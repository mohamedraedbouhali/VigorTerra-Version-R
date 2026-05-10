import { useState } from 'react'
import { Link, Navigate, useNavigate } from 'react-router-dom'
import { useAuth } from '../context/AuthContext'
import { useLanguage } from '../context/LanguageContext'
import './Auth.css'

export default function Login() {
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [error, setError] = useState('')
  const { login, isAuthenticated } = useAuth()
  const { language } = useLanguage()
  const navigate = useNavigate()
  const from = '/'

  const copy = {
    en: {
      sideTitle: 'Welcome back to VigorTerra',
      sideText: 'Sign in to manage your profile, run crop yield predictions, and access trusted agriculture resources.',
      f1: 'Profile and account settings',
      f2: 'Yield estimation with climate and soil inputs',
      f3: 'Curated data sources and videos',
      p1: 'Secure sign in',
      p2: 'Fast access',
      title: 'Sign in',
      subtitle: 'Access your agricultural prediction dashboard.',
      email: 'Email',
      password: 'Password',
      btn: 'Sign in',
      helper: 'Use the same email and password you created during registration.',
      switchLead: 'New here?',
      switchLink: 'Create account',
      fail: 'Unable to sign in.',
    },
    fr: {
      sideTitle: 'Bienvenue sur VigorTerra',
      sideText: 'Connectez-vous pour gerer votre profil, lancer des predictions de rendement et acceder a des ressources agricoles fiables.',
      f1: 'Profil et parametres du compte',
      f2: 'Estimation du rendement avec donnees climat et sol',
      f3: 'Sources de donnees et videos selectionnees',
      p1: 'Connexion securisee',
      p2: 'Acces rapide',
      title: 'Connexion',
      subtitle: 'Accedez a votre tableau de prediction agricole.',
      email: 'Email',
      password: 'Mot de passe',
      btn: 'Se connecter',
      helper: 'Utilisez le meme email et mot de passe crees lors de votre inscription.',
      switchLead: 'Nouveau ici ?',
      switchLink: 'Creer un compte',
      fail: 'Connexion impossible.',
    },
    ar: {
      sideTitle: 'مرحبا بعودتك إلى VigorTerra',
      sideText: 'سجل الدخول لإدارة ملفك الشخصي وتشغيل توقعات المردودية والوصول إلى موارد زراعية موثوقة.',
      f1: 'ملف شخصي وإعدادات الحساب',
      f2: 'تقدير المردودية بمعطيات المناخ والتربة',
      f3: 'مصادر بيانات وفيديوهات مختارة',
      p1: 'دخول آمن',
      p2: 'وصول سريع',
      title: 'تسجيل الدخول',
      subtitle: 'ادخل إلى لوحة توقعاتك الزراعية.',
      email: 'البريد الإلكتروني',
      password: 'كلمة المرور',
      btn: 'دخول',
      helper: 'استعمل نفس البريد وكلمة المرور التي أنشأتها أثناء التسجيل.',
      switchLead: 'جديد هنا؟',
      switchLink: 'إنشاء حساب',
      fail: 'تعذر تسجيل الدخول.',
    },
  }

  const text = copy[language] || copy.en

  if (isAuthenticated) {
    return <Navigate to={from} replace />
  }

  const handleSubmit = (e) => {
    e.preventDefault()
    setError('')
    const result = login(email, password)
    if (result.success) {
      navigate(from, { replace: true })
    } else {
      setError(result.error || text.fail)
    }
  }

  return (
    <div className="auth-page">
      <div className="auth-layout">
        <aside className="auth-side">
          <h2 className="auth-side-title">{text.sideTitle}</h2>
          <p className="auth-side-text">{text.sideText}</p>
          <ul className="auth-side-list">
            <li>{text.f1}</li>
            <li>{text.f2}</li>
            <li>{text.f3}</li>
          </ul>
          <div className="auth-pill-row" aria-hidden="true">
            <span className="auth-pill">{text.p1}</span>
            <span className="auth-pill">{text.p2}</span>
          </div>
        </aside>

        <div className="auth-card">
          <div className="auth-brand">
            <div className="auth-logo-wrap">
              <img src="/logo.png" alt="VigorTerra" className="auth-logo" />
            </div>
            <div>
              <p className="auth-brand-name">VigorTerra</p>
              <p className="auth-brand-tag">Smart Agriculture Intelligence</p>
            </div>
          </div>
          <h1 className="auth-title">{text.title}</h1>
          <p className="auth-subtitle">{text.subtitle}</p>
          <form className="auth-form" onSubmit={handleSubmit}>
            {error && <p className="auth-error">{error}</p>}
            <label>
              {text.email}
              <input
                type="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                placeholder="user@gmail.com"
                autoComplete="email"
                required
              />
            </label>
            <label>
              {text.password}
              <input
                type="password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                placeholder="••••••••"
                autoComplete="current-password"
                required
              />
            </label>
            <button type="submit" className="auth-btn">{text.btn}</button>
            <p className="auth-helper">{text.helper}</p>
          </form>

          <p className="auth-switch">
            {text.switchLead} <Link to="/signup">{text.switchLink}</Link>
          </p>
        </div>
      </div>
    </div>
  )
}
