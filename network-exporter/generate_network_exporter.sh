#!/bin/bash
set -euo pipefail

# Generate network_exporter.yml from AutoGlue API
# Usage: ./generate_network_exporter.sh <API_KEY>

API_ENDPOINT="https://autoglue.glueopshosted.com/api/v1"
OUTPUT_FILE="network_exporter.yml"

# Check for API key argument
if [[ $# -lt 1 ]]; then
    echo "Usage: $0 <API_KEY>"
    echo "  API_KEY: Your AutoGlue user API key"
    exit 1
fi

API_KEY="$1"

# API helper function
api_call() {
    local path="$1"
    local org_id="${2:-}"
    
    local headers=(-H "X-API-KEY: $API_KEY")
    [[ -n "$org_id" ]] && headers+=(-H "X-Org-ID: $org_id")
    
    curl -s -X GET "${headers[@]}" "$API_ENDPOINT$path"
}

echo "Fetching organizations..."
orgs=$(api_call "/orgs")

if [[ -z "$orgs" ]] || ! echo "$orgs" | jq -e '.' >/dev/null 2>&1; then
    echo "Error: Failed to fetch organizations. Check your API key."
    exit 1
fi

org_count=$(echo "$orgs" | jq 'length')
echo "Found $org_count organization(s)"

# Collect all targets
targets=""

# Loop through each organization
while IFS= read -r org_line; do
    org_id=$(echo "$org_line" | cut -d'|' -f1)
    org_name=$(echo "$org_line" | cut -d'|' -f2)
    
    echo "Processing org: $org_name"
    
    # Fetch clusters for this org
    clusters=$(api_call "/clusters" "$org_id")
    
    if [[ -z "$clusters" ]] || ! echo "$clusters" | jq -e '.' >/dev/null 2>&1; then
        echo "  No clusters found or error fetching clusters"
        continue
    fi
    
    cluster_count=$(echo "$clusters" | jq 'length')
    echo "  Found $cluster_count cluster(s)"
    
    # Loop through each cluster
    while IFS= read -r cluster_line; do
        [[ -z "$cluster_line" ]] && continue
        
        cluster_id=$(echo "$cluster_line" | cut -d'|' -f1)
        cluster_name=$(echo "$cluster_line" | cut -d'|' -f2)
        
        echo "    Processing cluster: $cluster_name"
        
        # Fetch full cluster details
        cluster=$(api_call "/clusters/$cluster_id" "$org_id")
        
        if [[ -z "$cluster" ]] || ! echo "$cluster" | jq -e '.' >/dev/null 2>&1; then
            echo "      Error fetching cluster details"
            continue
        fi
        
        # Extract bastion server if it has a public IP
        bastion_hostname=$(echo "$cluster" | jq -r '.bastion_server.hostname // empty')
        bastion_public_ip=$(echo "$cluster" | jq -r '.bastion_server.public_ip_address // empty')
        
        if [[ -n "$bastion_hostname" ]] && [[ -n "$bastion_public_ip" ]] && [[ "$bastion_public_ip" != "null" ]]; then
            target_name="${cluster_name}-bastion-${bastion_hostname}"
            targets+="  - name: ${target_name}
    host: ${bastion_public_ip}
    type: ICMP
"
            echo "      Added: $target_name ($bastion_public_ip)"
        fi
        
        # Extract servers from node pools
        node_servers=$(echo "$cluster" | jq -r '.node_pools[]?.servers[]? | "\(.hostname)|\(.public_ip_address // "")|\(.role // "")"' 2>/dev/null || true)
        
        while IFS= read -r server_line; do
            [[ -z "$server_line" ]] && continue
            
            hostname=$(echo "$server_line" | cut -d'|' -f1)
            public_ip=$(echo "$server_line" | cut -d'|' -f2)
            role=$(echo "$server_line" | cut -d'|' -f3)
            
            # Skip if no public IP
            if [[ -z "$public_ip" ]] || [[ "$public_ip" == "null" ]] || [[ "$public_ip" == "N/A" ]]; then
                continue
            fi
            
            target_name="${cluster_name}-${role}-${hostname}"
            targets+="  - name: ${target_name}
    host: ${public_ip}
    type: ICMP
"
            echo "      Added: $target_name ($public_ip)"
        done <<< "$node_servers"
        
    done < <(echo "$clusters" | jq -r '.[] | "\(.id)|\(.name)"')
    
done < <(echo "$orgs" | jq -r '.[] | "\(.id)|\(.name)"')

# Check if we found any targets
if [[ -z "$targets" ]]; then
    echo ""
    echo "Warning: No servers with public IPs found!"
    exit 1
fi

# Write the output file
cat > "$OUTPUT_FILE" << 'EOF'
# Main Config
conf:
  refresh: 15m

# Specific Protocol settings
icmp:
  interval: 3s
  timeout: 1s
  count: 1

mtr:
  interval: 3s
  timeout: 500ms
  max-hops: 30
  count: 6

tcp:
  interval: 3s
  timeout: 1s

http_get:
  interval: 15m
  timeout: 5s

# Target list and settings
targets:
EOF

echo "$targets" >> "$OUTPUT_FILE"

echo ""
echo "Generated $OUTPUT_FILE successfully!"
target_count=$(echo "$targets" | grep -c "^  - name:" || true)
echo "Total targets: $target_count"
