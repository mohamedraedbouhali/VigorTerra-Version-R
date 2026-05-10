import { useLanguage } from '../context/LanguageContext'
import './LanguageSwitcher.css'

const options = [
  { code: 'en', label: 'EN', title: 'English' },
  { code: 'fr', label: 'FR', title: 'Francais' },
  { code: 'ar', label: 'AR', title: 'Arabic' },
]

export default function LanguageSwitcher() {
  const { language, setLanguage } = useLanguage()

  return (
    <div className="language-switcher" role="group" aria-label="Language selector">
      <span className="language-switcher-icon" aria-hidden="true">
        🌐
      </span>
      <div className="language-switcher-list">
        {options.map((option) => (
          <button
            key={option.code}
            type="button"
            onClick={() => setLanguage(option.code)}
            className={option.code === language ? 'lang-btn active' : 'lang-btn'}
            title={option.title}
            aria-label={option.title}
            aria-pressed={option.code === language}
          >
            {option.label}
          </button>
        ))}
      </div>
    </div>
  )
}
