import { createContext, useContext, useState, useEffect } from 'react'

const AUTH_KEY = 'rendement_user'

const AuthContext = createContext(null)

const defaultUser = {
  name: 'VigorTerra User',
  age: '30',
  status: 'Farmer',
  farmType: 'Mixed Farming',
  phone: '',
  location: 'Tunisia',
  email: 'user@gmail.com',
  password: 'user',
  profilePic: '',
}

function getStoredUser() {
  const stored = localStorage.getItem(AUTH_KEY)
  if (!stored) return null

  try {
    const parsed = JSON.parse(stored)
    return parsed?.email ? { ...defaultUser, ...parsed } : null
  } catch (_) {
    return null
  }
}

export function AuthProvider({ children }) {
  const [user, setUser] = useState(null)

  useEffect(() => {
    const storedUser = getStoredUser()
    if (storedUser) {
      setUser(storedUser)
    }
  }, [])

  const login = (email, password) => {
    const normalizedEmail = (email || '').trim().toLowerCase()
    const account = getStoredUser() || defaultUser

    if (normalizedEmail === account.email && password === account.password) {
      const userData = { ...defaultUser, ...account, email: normalizedEmail }
      setUser(userData)
      localStorage.setItem(AUTH_KEY, JSON.stringify(userData))
      return { success: true }
    }

    return { success: false, error: 'Incorrect email or password.' }
  }

  const signUp = (payload) => {
    const normalizedEmail = (payload.email || '').trim().toLowerCase()
    const trimmedPassword = (payload.password || '').trim()
    const trimmedName = (payload.name || '').trim()
    const trimmedAge = `${payload.age || ''}`.trim()
    const trimmedStatus = (payload.status || '').trim()
    const trimmedFarmType = (payload.farmType || '').trim()
    const trimmedPhone = (payload.phone || '').trim()
    const trimmedLocation = (payload.location || '').trim()

    if (!trimmedName || !normalizedEmail || !trimmedPassword) {
      return { success: false, error: 'Name, email, and password are required.' }
    }

    if (trimmedPassword.length < 3) {
      return { success: false, error: 'Password must contain at least 3 characters.' }
    }

    const userData = {
      ...defaultUser,
      name: trimmedName,
      age: trimmedAge || defaultUser.age,
      status: trimmedStatus || defaultUser.status,
      farmType: trimmedFarmType || defaultUser.farmType,
      phone: trimmedPhone,
      location: trimmedLocation || defaultUser.location,
      email: normalizedEmail,
      password: trimmedPassword,
      profilePic: '',
    }

    setUser(userData)
    localStorage.setItem(AUTH_KEY, JSON.stringify(userData))
    return { success: true }
  }

  const updateProfile = (updates) => {
    if (!user) return { success: false, error: 'User is not authenticated.' }

    const normalizedEmail = (updates.email || user.email || '').trim().toLowerCase()
    const requestedPassword = (updates.password || '').trim()
    const nextPassword = requestedPassword || user.password

    if (!normalizedEmail) {
      return { success: false, error: 'Email is required.' }
    }

    if (!nextPassword || nextPassword.length < 3) {
      return { success: false, error: 'Invalid password (minimum 3 characters).' }
    }

      const nextUser = {
        ...defaultUser,
        ...user,
        ...updates,
        email: normalizedEmail,
        password: nextPassword,
        age: `${updates.age ?? user.age ?? ''}`,
        status: `${updates.status ?? user.status ?? defaultUser.status}`.trim() || defaultUser.status,
        farmType: `${updates.farmType ?? user.farmType ?? defaultUser.farmType}`.trim() || defaultUser.farmType,
        phone: `${updates.phone ?? user.phone ?? ''}`.trim(),
        location: `${updates.location ?? user.location ?? defaultUser.location}`.trim() || defaultUser.location,
      }


    setUser(nextUser)
    localStorage.setItem(AUTH_KEY, JSON.stringify(nextUser))
    return { success: true }
  }

  const logout = () => {
    setUser(null)
    localStorage.removeItem(AUTH_KEY)
  }

  return (
    <AuthContext.Provider
      value={{ user, login, signUp, updateProfile, logout, isAuthenticated: !!user }}
    >
      {children}
    </AuthContext.Provider>
  )
}

export function useAuth() {
  const ctx = useContext(AuthContext)
  if (!ctx) throw new Error('useAuth must be used within AuthProvider')
  return ctx
}
