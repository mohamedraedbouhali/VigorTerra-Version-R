import Layout from '../components/Layout'
import { useLanguage } from '../context/LanguageContext'
import './Home.css'

const articleCatalog = {
  en: [
    {
      id: 1,
      title: 'Ministry of Agriculture Portal (Tunisia)',
      excerpt: 'Official portal with national programs, sector news, and institutional information for Tunisian agriculture.',
      icon: '🏛️',
      href: 'http://www.agriculture.tn/',
    },
    {
      id: 2,
      title: 'ONAGRI - National Agriculture Observatory',
      excerpt: 'Reference platform for agricultural statistics, economic analysis, and sector monitoring in Tunisia.',
      icon: '📚',
      href: 'http://www.onagri.nat.tn/',
    },
    {
      id: 3,
      title: 'Agridata Tunisia',
      excerpt: 'Agricultural data platform with datasets, resources, and analytical content for informed decisions.',
      icon: '📊',
      href: 'https://www.agridata.tn/ar/',
    },
    {
      id: 4,
      title: 'Technical Factsheets from the Ministry',
      excerpt: 'Direct access to practical technical sheets for farmers, producers, and field advisors.',
      icon: '🧾',
      href: 'http://www.agriculture.tn/?page_id=714',
    },
    {
      id: 5,
      title: 'FAOSTAT - FAO',
      excerpt: 'Global food and agriculture indicators to compare trends and support planning.',
      icon: '🌍',
      href: 'https://www.fao.org/faostat/en/#home',
    },
    {
      id: 6,
      title: 'Access Agriculture',
      excerpt: 'Training videos and field knowledge to speed up practical adoption.',
      icon: '🎬',
      href: 'https://www.accessagriculture.org/',
    },
  ],
  fr: [
    {
      id: 1,
      title: "Portail du Ministere de l'Agriculture (Tunisie)",
      excerpt: 'Portail officiel avec les programmes nationaux, les actualites du secteur et les informations institutionnelles.',
      icon: '🏛️',
      href: 'http://www.agriculture.tn/',
    },
    {
      id: 2,
      title: 'ONAGRI - Observatoire National de l Agriculture',
      excerpt: 'Plateforme de reference pour les statistiques agricoles, les analyses economiques et le suivi du secteur.',
      icon: '📚',
      href: 'http://www.onagri.nat.tn/',
    },
    {
      id: 3,
      title: 'Agridata Tunisia',
      excerpt: 'Plateforme de donnees agricoles proposant des jeux de donnees et des ressources pour une meilleure decision.',
      icon: '📊',
      href: 'https://www.agridata.tn/ar/',
    },
    {
      id: 4,
      title: 'Fiches techniques du ministere',
      excerpt: 'Acces direct a des fiches techniques utiles pour les agriculteurs et les acteurs de terrain.',
      icon: '🧾',
      href: 'http://www.agriculture.tn/?page_id=714',
    },
    {
      id: 5,
      title: 'FAOSTAT - FAO',
      excerpt: 'Indicateurs agricoles et alimentaires mondiaux pour comparer les tendances et planifier efficacement.',
      icon: '🌍',
      href: 'https://www.fao.org/faostat/en/#home',
    },
    {
      id: 6,
      title: 'Access Agriculture',
      excerpt: 'Bibliotheque de videos de formation et de conseils pratiques pour accelerer l adoption sur le terrain.',
      icon: '🎬',
      href: 'https://www.accessagriculture.org/',
    },
  ],
  ar: [
    {
      id: 1,
      title: 'بوابة وزارة الفلاحة التونسية',
      excerpt: 'بوابة رسمية تضم البرامج الوطنية واخبار القطاع والمعلومات المؤسساتية للفلاحة في تونس.',
      icon: '🏛️',
      href: 'http://www.agriculture.tn/',
    },
    {
      id: 2,
      title: 'المرصد الوطني للفلاحة - ONAGRI',
      excerpt: 'منصة مرجعية للاحصائيات الفلاحية والتحليل الاقتصادي ومتابعة تطور القطاع.',
      icon: '📚',
      href: 'http://www.onagri.nat.tn/',
    },
    {
      id: 3,
      title: 'Agridata Tunisia',
      excerpt: 'منصة بيانات فلاحية توفر مجموعات بيانات وموارد تحليلية لدعم القرار.',
      icon: '📊',
      href: 'https://www.agridata.tn/ar/',
    },
    {
      id: 4,
      title: 'مطويات تقنية من الوزارة',
      excerpt: 'وصول مباشر الى موارد تقنية مفيدة للفلاحين والمتدخلين في الميدان.',
      icon: '🧾',
      href: 'http://www.agriculture.tn/?page_id=714',
    },
    {
      id: 5,
      title: 'FAOSTAT - FAO',
      excerpt: 'مؤشرات عالمية حول الغذاء والفلاحة لمقارنة الاتجاهات ودعم التخطيط.',
      icon: '🌍',
      href: 'https://www.fao.org/faostat/en/#home',
    },
    {
      id: 6,
      title: 'Access Agriculture',
      excerpt: 'مكتبة فيديوهات تدريبية ومعارف ميدانية لدعم التطبيق العملي.',
      icon: '🎬',
      href: 'https://www.accessagriculture.org/',
    },
  ],
}

export default function Home() {
  const { language } = useLanguage()

  const copy = {
    en: {
      tagline: 'Agricultural yield prediction using climate and soil conditions in Tunisia',
      subTagline: 'A practical decision platform to transform reliable data into measurable farm impact.',
      chips: ['Climate intelligence', 'Soil diagnostics', 'Yield forecasting'],
      articleTitle: 'News and resources',
      articleDesc: 'Explore trusted references on agriculture, data, and yield prediction.',
      cta: 'Open resource',
      insightTitle: 'Featured insights',
      insights: [
        {
          title: 'Climate pressure is increasing',
          text: 'Rainfall variability is now a major driver of yield uncertainty. Monitoring monthly anomalies helps reduce risk.',
        },
        {
          title: 'Soil balance matters',
          text: 'NPK and pH optimization can strongly improve yield stability before any expensive intervention.',
        },
        {
          title: 'Data-led decisions scale faster',
          text: 'Collecting clean field data improves prediction quality and accelerates practical recommendations.',
        },
      ],
    },
    fr: {
      tagline: 'Prediction du rendement agricole a partir des conditions climatiques et du sol en Tunisie',
      subTagline: 'Une plateforme pratique d aide a la decision pour transformer des donnees fiables en impact concret.',
      chips: ['Intelligence climatique', 'Diagnostic des sols', 'Prevision du rendement'],
      articleTitle: 'Actualites et ressources',
      articleDesc: 'Explorez des references fiables sur l agriculture, les jeux de donnees et la prediction des rendements.',
      cta: 'Ouvrir la ressource',
      insightTitle: 'Analyses a retenir',
      insights: [
        {
          title: 'La pression climatique augmente',
          text: 'La variabilite des pluies devient un facteur majeur d incertitude. Suivre les anomalies mensuelles limite le risque.',
        },
        {
          title: 'L equilibre du sol est decisif',
          text: 'L optimisation NPK et pH peut ameliorer durablement le rendement avant les interventions couteuses.',
        },
        {
          title: 'La decision basee sur les donnees va plus vite',
          text: 'Une collecte terrain propre ameliore la qualite de prediction et la pertinence des recommandations.',
        },
      ],
    },
    ar: {
      tagline: 'توقع المردودية الزراعية اعتمادا على الظروف المناخية وخصائص التربة في تونس',
      subTagline: 'منصة عملية لدعم القرار وتحويل البيانات الموثوقة الى اثر ملموس داخل الضيعة.',
      chips: ['ذكاء مناخي', 'تشخيص التربة', 'توقع المردودية'],
      articleTitle: 'اخبار وموارد',
      articleDesc: 'اكتشف مراجع موثوقة حول الزراعة والبيانات وتوقع المردودية.',
      cta: 'فتح المورد',
      insightTitle: 'خلاصات مهمة',
      insights: [
        {
          title: 'الضغط المناخي في ارتفاع',
          text: 'تذبذب التساقطات اصبح عاملا اساسيا في عدم استقرار المردودية. مراقبة الانحرافات الشهرية تقلص المخاطر.',
        },
        {
          title: 'توازن التربة عنصر حاسم',
          text: 'تحسين NPK ودرجة الحموضة يرفع استقرار المردودية قبل اي تدخل مكلف.',
        },
        {
          title: 'القرار المبني على البيانات اسرع',
          text: 'جمع معطيات ميدانية نظيفة يحسن جودة التوقع ويجعل التوصيات اكثر فاعلية.',
        },
      ],
    },
  }

  const text = copy[language] || copy.en
  const articles = articleCatalog[language] || articleCatalog.en

  return (
    <Layout>
      <section className="home-hero">
        <div className="home-hero-inner">
          <img src="/logo.png" alt="VigorTerra" className="home-logo" />
          <div className="home-copy">
            <h1 className="home-title">VigorTerra</h1>
            <p className="home-tagline">{text.tagline}</p>
            <p className="home-subtagline">{text.subTagline}</p>
            <div className="home-chip-row">
              {text.chips.map((chip) => (
                <span key={chip} className="home-chip">{chip}</span>
              ))}
            </div>
          </div>
        </div>
      </section>

      <section className="home-insights section">
        <div className="section-inner">
          <h2 className="section-title">{text.insightTitle}</h2>
          <div className="insight-grid">
            {text.insights.map((insight) => (
              <article className="insight-card" key={insight.title}>
                <h3>{insight.title}</h3>
                <p>{insight.text}</p>
              </article>
            ))}
          </div>
        </div>
      </section>

      <section className="home-articles">
        <div className="section-inner">
          <h2 className="section-title">{text.articleTitle}</h2>
          <p className="section-desc">{text.articleDesc}</p>
          <div className="articles-grid">
            {articles.map((article) => (
              <a
                key={article.id}
                className="article-card article-link"
                href={article.href}
                target="_blank"
                rel="noreferrer"
              >
                <span className="article-icon">{article.icon}</span>
                <h3 className="article-title">{article.title}</h3>
                <p className="article-excerpt">{article.excerpt}</p>
                <span className="article-cta">{text.cta} →</span>
              </a>
            ))}
          </div>
        </div>
      </section>
    </Layout>
  )
}
