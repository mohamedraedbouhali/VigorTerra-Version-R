import { Routes, Route, Navigate } from 'react-router-dom'
import ProtectedRoute from './components/ProtectedRoute'
import LanguageSwitcher from './components/LanguageSwitcher'
import Login from './pages/Login'
import SignUp from './pages/SignUp'
import Profile from './pages/Profile'
import Home from './pages/Home'
import SourcesPage from './pages/SourcesPage'
import DatasetPage from './pages/DatasetPage'
import PipelinePage from './pages/PipelinePage'
import TestPage from './pages/TestPage'
import AskMePage from './pages/AskMePage'
import './components/shared.css'

function App() {
  return (
    <>
      <LanguageSwitcher />
      <Routes>
        <Route path="/login" element={<Login />} />
        <Route path="/signup" element={<SignUp />} />
        <Route
          path="/profile"
          element={
            <ProtectedRoute>
              <Profile />
            </ProtectedRoute>
          }
        />
        <Route
          path="/"
          element={
            <ProtectedRoute>
              <Home />
            </ProtectedRoute>
          }
        />
        <Route
          path="/sources"
          element={
            <ProtectedRoute>
              <SourcesPage />
            </ProtectedRoute>
          }
        />
        <Route
          path="/dataset"
          element={
            <ProtectedRoute>
              <DatasetPage />
            </ProtectedRoute>
          }
        />
        <Route
          path="/pipeline"
          element={
            <ProtectedRoute>
              <PipelinePage />
            </ProtectedRoute>
          }
        />
        <Route
          path="/test"
          element={
            <ProtectedRoute>
              <TestPage />
            </ProtectedRoute>
          }
        />
        <Route
          path="/askme"
          element={
            <ProtectedRoute>
              <AskMePage />
            </ProtectedRoute>
          }
        />
        <Route path="*" element={<Navigate to="/login" replace />} />
      </Routes>
    </>
  )
}

export default App
