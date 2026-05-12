nsenter -t 2207 -m -- ls -la /app/ 2>/dev/null
echo "---"
nsenter -t 2207 -m -- cat /proc/1/cmdline 2>/dev/null | tr "\0" " "
echo ""
echo "---"
nsenter -t 2207 -m -- find /app -name "server*" -o -name "*.go" -o -name "stridemoor*" 2>/dev/null
