ask_yes_no() {
  while true; do
    read -p "$1 (s/n): " ans
    case "$ans" in
      s|S) return 0 ;;
      n|N) return 1 ;;
      *) echo "❌ responde s o n" ;;
    esac
  done
}
