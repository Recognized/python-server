#!/usr/bin/env bash
#
# Simple HTTP echo server using netcat.
# Listens on the specified port (default 8080) and echoes back
# the full request as the response body.
#
# Usage: ./echo-server.sh [port]
#

PORT="${1:-8080}"

echo "Starting HTTP echo server on port $PORT ..."
echo "Press Ctrl+C to stop."

while true; do
  # Read the full request into a temp file, then respond with it.
  TMPFILE=$(mktemp)

  # Use a single nc invocation: read lines until we get a blank line (end of headers),
  # then build the response and send it back.
  {
    REQUEST=""
    CONTENT_LENGTH=0

    # Read request line and headers
    while IFS= read -r line; do
      # Strip trailing \r
      line="${line%%$'\r'}"

      # Empty line signals end of headers
      [ -z "$line" ] && break

      REQUEST+="$line"$'\n'

      # Capture Content-Length if present
      if [[ "$line" =~ ^[Cc]ontent-[Ll]ength:\ *([0-9]+) ]]; then
        CONTENT_LENGTH="${BASH_REMATCH[1]}"
      fi
    done

    # Read body if Content-Length > 0
    BODY=""
    if [ "$CONTENT_LENGTH" -gt 0 ] 2>/dev/null; then
      BODY=$(dd bs=1 count="$CONTENT_LENGTH" 2>/dev/null)
    fi

    # Combine headers + body for the echo
    ECHO_BODY="${REQUEST}"
    if [ -n "$BODY" ]; then
      ECHO_BODY+=$'\n'"${BODY}"
    fi

    BODY_LENGTH=${#ECHO_BODY}

    # Build HTTP response
    RESPONSE="HTTP/1.1 200 OK"$'\r\n'
    RESPONSE+="Content-Type: text/plain"$'\r\n'
    RESPONSE+="Content-Length: ${BODY_LENGTH}"$'\r\n'
    RESPONSE+="Connection: close"$'\r\n'
    RESPONSE+=$'\r\n'
    RESPONSE+="${ECHO_BODY}"

    printf '%s' "$RESPONSE"

  } | nc -l "$PORT"

  rm -f "$TMPFILE"

  echo "[$(date '+%Y-%m-%d %H:%M:%S')] Handled request"
done
