import { createContext, useContext, useEffect, useMemo, useState } from 'react'

const STORAGE_KEY = 'vigorterra_language'

const TRANSLATIONS = {
  en: {
    nav: {
      home: 'Home',
      sources: 'Sources',
      dataset: 'Dataset',
      pipeline: 'Pipeline',
      test: 'User Test',
      profile: 'Profile',
      signedInAs: 'Signed in as',
      signIn: 'Sign in',
      signUp: 'Sign up',
      logout: 'Log out',
    },
    footer: {
      tag: 'Smart Agriculture Platform',
      desc: 'Data-driven crop yield prediction powered by trusted climate and soil data.',
      platform: 'Platform',
      resources: 'Resources',
      partners: 'Data Partners',
      yieldTest: 'Yield Test',
      dataSources: 'Data Sources',
      copy: 'All rights reserved.',
      note: 'Built for smart and sustainable agriculture in Tunisia.',
    },
    pages: {
      sources: { title: 'Data Sources' },
      dataset: { title: 'Dataset Overview' },
      pipeline: { title: 'Project Pipeline' },
      test: { title: 'User Prediction Test' },
    },
  },
  fr: {
    nav: {
      home: 'Accueil',
      sources: 'Sources',
      dataset: 'Jeu de donnees',
      pipeline: 'Pipeline',
      test: 'Test utilisateur',
      profile: 'Profil',
      signedInAs: 'Connecte en tant que',
      signIn: 'Connexion',
      signUp: 'Inscription',
      logout: 'Deconnexion',
    },
    footer: {
      tag: "Plateforme d'agriculture intelligente",
      desc: 'Prediction du rendement agricole basee sur des donnees climatiques et du sol fiables.',
      platform: 'Plateforme',
      resources: 'Ressources',
      partners: 'Partenaires de donnees',
      yieldTest: 'Test de rendement',
      dataSources: 'Sources de donnees',
      copy: 'Tous droits reserves.',
      note: "Concu pour une agriculture intelligente et durable en Tunisie.",
    },
    pages: {
      sources: { title: 'Sources de donnees' },
      dataset: { title: 'Apercu du jeu de donnees' },
      pipeline: { title: 'Pipeline du projet' },
      test: { title: 'Test de prediction utilisateur' },
    },
  },
  ar: {
    nav: {
      home: 'الرئيسية',
      sources: 'المصادر',
      dataset: 'البيانات',
      pipeline: 'المسار',
      test: 'اختبار المستخدم',
      profile: 'الملف الشخصي',
      signedInAs: 'تسجيل الدخول باسم',
      signIn: 'تسجيل الدخول',
      signUp: 'انشاء حساب',
      logout: 'تسجيل الخروج',
    },
    footer: {
      tag: 'منصة الزراعة الذكية',
      desc: 'توقع مردودية المحاصيل بالاعتماد على بيانات موثوقة للمناخ والتربة.',
      platform: 'المنصة',
      resources: 'الموارد',
      partners: 'شركاء البيانات',
      yieldTest: 'اختبار المردودية',
      dataSources: 'مصادر البيانات',
      copy: 'جميع الحقوق محفوظة.',
      note: 'تم التطوير من اجل زراعة ذكية ومستدامة في تونس.',
    },
  },
}

const LanguageContext = createContext(null)

function getByPath(obj, path) {
  return path.split('.').reduce((acc, key) => (acc && acc[key] !== undefined ? acc[key] : undefined), obj)
}

export function LanguageProvider({ children }) {
  const [language, setLanguage] = useState(() => {
    const saved = localStorage.getItem(STORAGE_KEY)
    if (saved === 'en' || saved === 'fr' || saved === 'ar') return saved
    return 'en'
  })

  useEffect(() => {
    localStorage.setItem(STORAGE_KEY, language)
    const isRTL = language === 'ar'
    document.documentElement.lang = language
    document.documentElement.dir = isRTL ? 'rtl' : 'ltr'
    document.body.classList.toggle('rtl', isRTL)
  }, [language])

  const value = useMemo(
    () => ({
      language,
      setLanguage,
      isRTL: language === 'ar',
      t: (key, fallback = key) => {
        const langPack = TRANSLATIONS[language] || TRANSLATIONS.en
        const enPack = TRANSLATIONS.en
        return getByPath(langPack, key) ?? getByPath(enPack, key) ?? fallback
      },
    }),
    [language],
  )

  return <LanguageContext.Provider value={value}>{children}</LanguageContext.Provider>
}

export function useLanguage() {
  const context = useContext(LanguageContext)
  if (!context) {
    throw new Error('useLanguage must be used inside LanguageProvider')
  }
  return context
}
