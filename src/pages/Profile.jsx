import { useEffect, useState } from 'react'
import { Link } from 'react-router-dom'
import { useAuth } from '../context/AuthContext'
import { useLanguage } from '../context/LanguageContext'
import './Profile.css'

export default function Profile() {
  const { user, updateProfile, logout } = useAuth()
  const { language } = useLanguage()
  const [name, setName] = useState('')
  const [age, setAge] = useState('')
  const [status, setStatus] = useState('Farmer')
  const [farmType, setFarmType] = useState('Mixed Farming')
  const [phone, setPhone] = useState('')
  const [location, setLocation] = useState('')
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [profilePic, setProfilePic] = useState('')
  const [success, setSuccess] = useState('')
  const [error, setError] = useState('')

  const copy = {
    en: {
      title: 'My profile',
      desc: 'Update your account information and profile picture.',
      success: 'Profile updated successfully.',
      imageError: 'Please choose a valid image file.',
      nameRequired: 'Name is required.',
      emailRequired: 'Email is required.',
      saveFail: 'Unable to update profile.',
      name: 'Full name',
      age: 'Age',
      status: 'Status',
      farmType: 'Farm type',
      phone: 'Phone number',
      location: 'Location',
      email: 'Email address',
      password: 'Password',
      picture: 'Profile picture',
      helper: 'Your profile photo and name are shown in the navigation bar.',
      save: 'Save changes',
      home: 'Home',
      logout: 'Log out',
    },
    fr: {
      title: 'Mon profil',
      desc: 'Mettez a jour vos informations de compte et votre photo de profil.',
      success: 'Profil mis a jour avec succes.',
      imageError: 'Veuillez choisir un fichier image valide.',
      nameRequired: 'Le nom est obligatoire.',
      emailRequired: "L'email est obligatoire.",
      saveFail: 'Mise a jour du profil impossible.',
      name: 'Nom complet',
      age: 'Age',
      status: 'Statut',
      farmType: 'Type de ferme',
      phone: 'Numero de telephone',
      location: 'Localisation',
      email: 'Adresse email',
      password: 'Mot de passe',
      picture: 'Photo de profil',
      helper: 'Votre photo et votre nom apparaissent dans la barre de navigation.',
      save: 'Enregistrer',
      home: 'Accueil',
      logout: 'Deconnexion',
    },
    ar: {
      title: 'ملفي الشخصي',
      desc: 'قم بتحديث معلومات حسابك وصورة ملفك الشخصي.',
      success: 'تم تحديث الملف الشخصي بنجاح.',
      imageError: 'يرجى اختيار ملف صورة صالح.',
      nameRequired: 'الاسم مطلوب.',
      emailRequired: 'البريد الإلكتروني مطلوب.',
      saveFail: 'تعذر تحديث الملف الشخصي.',
      name: 'الاسم الكامل',
      age: 'العمر',
      status: 'الصفة',
      farmType: 'نوع المزرعة',
      phone: 'رقم الهاتف',
      location: 'الموقع',
      email: 'البريد الإلكتروني',
      password: 'كلمة المرور',
      picture: 'صورة الملف الشخصي',
      helper: 'تظهر صورة ملفك واسمك في شريط التنقل.',
      save: 'حفظ التغييرات',
      home: 'الرئيسية',
      logout: 'تسجيل الخروج',
    },
  }

  const text = copy[language] || copy.en

  useEffect(() => {
    if (!user) return
    setName(user.name || '')
    setAge(user.age || '')
    setStatus(user.status || 'Farmer')
    setFarmType(user.farmType || 'Mixed Farming')
    setPhone(user.phone || '')
    setLocation(user.location || '')
    setEmail(user.email || '')
    setPassword(user.password || '')
    setProfilePic(user.profilePic || '')
  }, [user])

  const handleFileChange = (event) => {
    const file = event.target.files?.[0]
    if (!file) return

    if (!file.type.startsWith('image/')) {
      setError(text.imageError)
      return
    }

    const reader = new FileReader()
    reader.onload = () => {
      const imageData = typeof reader.result === 'string' ? reader.result : ''
      setProfilePic(imageData)
      setError('')
    }
    reader.readAsDataURL(file)
  }

  const handleSubmit = (event) => {
    event.preventDefault()
    setSuccess('')
    setError('')

    if (!name.trim()) {
      setError(text.nameRequired)
      return
    }

    if (!email.trim()) {
      setError(text.emailRequired)
      return
    }

    const result = updateProfile({
      name: name.trim(),
      age: age.trim(),
      status: status.trim(),
      farmType: farmType.trim(),
      phone: phone.trim(),
      location: location.trim(),
      email: email.trim(),
      password: password.trim(),
      profilePic,
    })

    if (result.success) {
      setSuccess(text.success)
    } else {
      setError(result.error || text.saveFail)
    }
  }

  const avatarLetter = (name || email || 'U').charAt(0).toUpperCase()

  return (
    <div className="profile-page">
      <div className="profile-card">
        <div className="profile-brand">
          <img src="/logo.png" alt="VigorTerra" className="profile-logo" />
          <p className="profile-brand-name">VigorTerra</p>
        </div>

        <div className="profile-avatar-wrap">
          {profilePic ? (
            <img src={profilePic} alt="Profile" className="profile-avatar-image" />
          ) : (
            <div className="profile-avatar">{avatarLetter}</div>
          )}
        </div>

        <h1 className="profile-title">{text.title}</h1>
        <p className="profile-desc">{text.desc}</p>

        <form className="profile-form" onSubmit={handleSubmit}>
          {success && <p className="profile-success">{success}</p>}
          {error && <p className="profile-error">{error}</p>}

          <label>
            {text.name}
            <input type="text" value={name} onChange={(e) => setName(e.target.value)} required />
          </label>

          <div className="profile-two-col">
            <label>
              {text.age}
              <input type="number" min="1" max="120" value={age} onChange={(e) => setAge(e.target.value)} />
            </label>

            <label>
              {text.status}
              <select value={status} onChange={(e) => setStatus(e.target.value)}>
                <option value="Farmer">Farmer</option>
                <option value="Agronomist">Agronomist</option>
                <option value="Researcher">Researcher</option>
                <option value="Student">Student</option>
              </select>
            </label>
          </div>

          <div className="profile-two-col">
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

            <label>
              {text.phone}
              <input
                type="tel"
                value={phone}
                onChange={(e) => setPhone(e.target.value)}
                placeholder="e.g. +216 12 345 678"
              />
            </label>
          </div>

          <label>
            {text.location}
            <input type="text" value={location} onChange={(e) => setLocation(e.target.value)} />
          </label>

          <label>
            {text.email}
            <input type="email" value={email} onChange={(e) => setEmail(e.target.value)} required />
          </label>

          <label>
            {text.password}
            <input
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              placeholder="Minimum 3 characters"
            />
          </label>

          <label>
            {text.picture}
            <input type="file" accept="image/*" onChange={handleFileChange} />
          </label>
          <p className="profile-helper">{text.helper}</p>

          <div className="profile-actions">
            <button type="submit" className="profile-btn profile-btn-primary">
              {text.save}
            </button>
            <Link to="/" className="profile-btn profile-btn-outline">
              {text.home}
            </Link>
            <button type="button" onClick={logout} className="profile-btn profile-btn-outline">
              {text.logout}
            </button>
          </div>
        </form>
      </div>
    </div>
  )
}
