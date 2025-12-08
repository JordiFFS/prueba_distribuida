import { useState } from 'react'
import './App.css'

function App() {
  const [count, setCount] = useState(0)

  return (
    <>
      <div>
        <h1>¡Hola Mundo desde React + Vite!</h1>
        <p>Esta es una aplicación desplegada en AWS</p>
      </div>
      <div className="card">
        <button onClick={() => setCount((count) => count + 1)}>
          Contador: {count}
        </button>
      </div>
    </>
  )
}

export default App