export default function Home() {
  // ... rest of the code remains the same
  socketRef.current = new WebSocket('ws://localhost:8000/ws')
}