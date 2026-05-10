import { Link, useLocation } from 'react-router-dom'
import { useAuth } from '../context/AuthContext'
import { useLanguage } from '../context/LanguageContext'
import './Header.css'

export default function Header() {
  const { user, logout } = useAuth()
  const { t } = useLanguage()
  const location = useLocation()
  const initials = (user?.name || user?.email || 'U').trim().charAt(0).toUpperCase()

  return (
    <header className="header">
      <div className="header-inner header-inner--nav-only">
        <nav className="nav">
          <Link to="/" className={location.pathname === '/' ? 'nav-link active' : 'nav-link'}>
            {t('nav.home', 'Home')}
          </Link>
          <Link to="/sources" className={location.pathname === '/sources' ? 'nav-link active' : 'nav-link'}>
            {t('nav.sources', 'Sources')}
          </Link>
          <Link to="/dataset" className={location.pathname === '/dataset' ? 'nav-link active' : 'nav-link'}>
            {t('nav.dataset', 'Dataset')}
          </Link>
          <Link to="/pipeline" className={location.pathname === '/pipeline' ? 'nav-link active' : 'nav-link'}>
            {t('nav.pipeline', 'Pipeline')}
          </Link>
          <Link to="/test" className={location.pathname === '/test' ? 'nav-link active' : 'nav-link'}>
            {t('nav.test', 'User Test')}
          </Link>
          <Link to="/askme" className={location.pathname === '/askme' ? 'nav-link active' : 'nav-link'}>
            {t('nav.askme', 'Ask Me!')}
          </Link>
          {user ? (
            <>
              <Link to="/profile" className={location.pathname === '/profile' ? 'nav-link active' : 'nav-link'}>
                {t('nav.profile', 'Profile')}
              </Link>
              <Link
                to="/profile"
                className={location.pathname === '/profile' ? 'header-user-chip header-user-chip-link active' : 'header-user-chip header-user-chip-link'}
                title={user.name || user.email}
              >
                {user.profilePic ? (
                  <img src={user.profilePic} alt="User avatar" className="header-user-avatar" />
                ) : (
                  <span className="header-user-avatar header-user-avatar-fallback">{initials}</span>
                )}
                <span className="header-user-meta">
                  <span className="header-user-label">{t('nav.signedInAs', 'Signed in as')}</span>
                  <span className="header-user-name">{user.name || user.email}</span>
                </span>
              </Link>
              <button type="button" onClick={logout} className="header-logout">
                {t('nav.logout', 'Log out')}
              </button>
            </>
          ) : (

            <>
              <Link to="/login" className="nav-link">{t('nav.signIn', 'Sign in')}</Link>
              <Link to="/signup" className="nav-link">{t('nav.signUp', 'Sign up')}</Link>
            </>
          )}

        </nav>
      </div>
    </header>
  )
}
