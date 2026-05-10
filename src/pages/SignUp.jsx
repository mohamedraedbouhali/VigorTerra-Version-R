import { useState } from 'react'
import { Link, Navigate, useNavigate } from 'react-router-dom'
import { useAuth } from '../context/AuthContext'
import { useLanguage } from '../context/LanguageContext'
import './Auth.css'

export default function SignUp() {
  const [name, setName] = useState('')
  const [age, setAge] = useState('')
  const [status, setStatus] = useState('Farmer')
  const [farmType, setFarmType] = useState('Mixed Farming')
  const [phone, setPhone] = useState('')
  const [location, setLocation] = useState('')
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [confirmPassword, setConfirmPassword] = useState('')
  const [error, setError] = useState('')
  const { signUp, isAuthenticated } = useAuth()
  const { language } = useLanguage()
  const navigate = useNavigate()

  const copy = {
    en: {
      sideTitle: 'Create your smart farming workspace',
      sideText: 'Build your account once, then keep your farming profile updated with role, farm type, and contact details.',
      title: 'Create account',
      subtitle: 'Set up your profile to start exploring the platform.',
      name: 'Full name',
      age: 'Age',
      status: 'Status',
      farmType: 'Farm type',
      phone: 'Phone number',
      location: 'Location',
      email: 'Email address',
      password: 'Password',
      confirm: 'Confirm password',
      helper: 'Tip: You can update your photo, name, and all details later from the profile page.',
      btn: 'Create account',
      switchLead: 'Already have an account?',
      switchLink: 'Sign in',
      mismatch: 'Passwords do not match.',
      fail: 'Unable to create account.',
    },
    fr: {
      sideTitle: 'Creez votre espace agricole intelligent',
      sideText: 'Creez votre compte puis gardez votre profil a jour avec votre role, type de ferme et contact.',
      title: 'Creer un compte',
      subtitle: 'Configurez votre profil pour commencer a utiliser la plateforme.',
      name: 'Nom complet',
      age: 'Age',
      status: 'Statut',
      farmType: 'Type de ferme',
      phone: 'Numero de telephone',
      location: 'Localisation',
      email: 'Adresse email',
      password: 'Mot de passe',
      confirm: 'Confirmer le mot de passe',
      helper: 'Astuce : vous pouvez modifier votre photo et vos informations plus tard depuis le profil.',
      btn: 'Creer le compte',
      switchLead: 'Vous avez deja un compte ?',
      switchLink: 'Connexion',
      mismatch: 'Les mots de passe ne correspondent pas.',
      fail: 'Creation du compte impossible.',
    },
    ar: {
      sideTitle: 'أنشئ مساحة الزراعة الذكية الخاصة بك',
      sideText: 'أنشئ حسابك مرة واحدة ثم حافظ على تحديث ملفك الفلاحي حسب الدور ونوع المزرعة ومعلومات الاتصال.',
      title: 'إنشاء حساب',
      subtitle: 'قم بإعداد ملفك الشخصي لبدء استخدام المنصة.',
      name: 'الاسم الكامل',
      age: 'العمر',
      status: 'الصفة',
      farmType: 'نوع المزرعة',
      phone: 'رقم الهاتف',
      location: 'الموقع',
      email: 'البريد الإلكتروني',
      password: 'كلمة المرور',
      confirm: 'تأكيد كلمة المرور',
      helper: 'ملاحظة: يمكنك تعديل الصورة وكل البيانات لاحقا من صفحة الملف الشخصي.',
      btn: 'إنشاء الحساب',
      switchLead: 'لديك حساب بالفعل؟',
      switchLink: 'تسجيل الدخول',
      mismatch: 'كلمتا المرور غير متطابقتين.',
      fail: 'تعذر إنشاء الحساب.',
    },
  }

  const text = copy[language] || copy.en

  if (isAuthenticated) {
    return <Navigate to="/profile" replace />
  }

  const handleSubmit = (e) => {
    e.preventDefault()
    setError('')

    if (password !== confirmPassword) {
      setError(text.mismatch)
      return
    }

    const result = signUp({
      name,
      age,
      status,
      farmType,
      phone,
      location,
      email,
      password,
    })

    if (result.success) {
      navigate('/profile', { replace: true })
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

            <div className="auth-grid">
              <label>
                {text.name}
                <input type="text" value={name} onChange={(e) => setName(e.target.value)} placeholder="e.g. Mohamed Ali" autoComplete="name" required />
              </label>

              <label>
                {text.age}
                <input type="number" min="1" max="120" value={age} onChange={(e) => setAge(e.target.value)} placeholder="e.g. 34" />
              </label>
            </div>

            <div className="auth-grid">
              <label>
                {text.status}
                <select value={status} onChange={(e) => setStatus(e.target.value)}>
                  <option value="Farmer">Farmer</option>
                  <option value="Agronomist">Agronomist</option>
                  <option value="Researcher">Researcher</option>
                  <option value="Student">Student</option>
                </select>
              </label>

              <label>
                {text.farmType}
                <select value={farmType} onChange={(e) => setFarmType(e.target.value)}>
                  <option value="Mixed Farming">Mixed Farming</option>
                  <option value="Cereal Farming">Cereal Farming</option>
                  <option value="Vegetable Farming">Vegetable Farming</option>
                  <option value="Olive Farming">Olive Farming</option>
                  <option value="Livestock">Livestock</option>
                </select>
              </label>
            </div>

            <div className="auth-grid">
              <label>
                {text.phone}
                <input type="tel" value={phone} onChange={(e) => setPhone(e.target.value)} placeholder="e.g. +216 12 345 678" autoComplete="tel" />
              </label>

              <label>
                {text.location}
                <input type="text" value={location} onChange={(e) => setLocation(e.target.value)} placeholder="e.g. Sfax, Tunisia" autoComplete="address-level2" />
              </label>
            </div>

            <label>
              {text.email}
              <input type="email" value={email} onChange={(e) => setEmail(e.target.value)} placeholder="user@gmail.com" autoComplete="email" required />
            </label>

            <div className="auth-grid">
              <label>
                {text.password}
                <input type="password" value={password} onChange={(e) => setPassword(e.target.value)} placeholder="Minimum 3 characters" autoComplete="new-password" required />
              </label>

              <label>
                {text.confirm}
                <input type="password" value={confirmPassword} onChange={(e) => setConfirmPassword(e.target.value)} placeholder="Repeat your password" autoComplete="new-password" required />
              </label>
            </div>

            <p className="auth-helper">{text.helper}</p>
            <button type="submit" className="auth-btn">{text.btn}</button>
          </form>

          <p className="auth-switch">
            {text.switchLead} <Link to="/login">{text.switchLink}</Link>
          </p>
        </div>
      </div>
    </div>
  )
}
