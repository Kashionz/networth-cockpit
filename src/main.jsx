import React, { useMemo, useState } from 'react';
import { createRoot } from 'react-dom/client';
import {
  ArrowUp,
  Check,
  ChevronDown,
  ChevronRight,
  Clock3,
  CreditCard,
  Eye,
  EyeOff,
  Gauge,
  LayoutDashboard,
  LineChart,
  MoreHorizontal,
  Plus,
  Settings,
  ShieldCheck,
  SlidersHorizontal,
  Upload,
  WalletCards,
} from 'lucide-react';
import './styles.css';

const ACCENTS = {
  slate: {
    '--c-accent': '#3a4a5c',
    '--c-accent-2': '#4d6378',
    '--c-accent-tint': '#eef1f5',
    '--c-accent-edge': '#c7d0db',
  },
  pine: {
    '--c-accent': '#3a5446',
    '--c-accent-2': '#4f6c5e',
    '--c-accent-tint': '#eaf0ec',
    '--c-accent-edge': '#c5d2cb',
  },
  ink: {
    '--c-accent': '#2a2a2a',
    '--c-accent-2': '#454545',
    '--c-accent-tint': '#f0efed',
    '--c-accent-edge': '#cdcbc6',
  },
  amber: {
    '--c-accent': '#7a5a2c',
    '--c-accent-2': '#8e6d3d',
    '--c-accent-tint': '#f4eee2',
    '--c-accent-edge': '#d8ccaf',
  },
};

const navItems = [
  { id: 'dashboard', icon: LayoutDashboard, label: '總覽 Dashboard' },
  { id: 'assets', icon: WalletCards, label: '資產 Assets' },
  { id: 'transactions', icon: CreditCard, label: '交易 Transactions', badge: '2' },
  { id: 'budget', icon: Clock3, label: '預算 Budget' },
  { id: 'portfolio', icon: LineChart, label: '配置 Portfolio' },
  { id: 'cards', icon: CreditCard, label: '信用卡 Cards' },
  { id: 'insights', icon: Gauge, label: '月度報告 Insights' },
];

const categories = [
  { id: 'food', label: '餐飲', bucket: '生活', color: 'var(--c-bud-living)' },
  { id: 'grocery', label: '生鮮超市', bucket: '生活', color: 'var(--c-bud-living)' },
  { id: 'transit', label: '交通', bucket: '生活', color: 'var(--c-bud-living)' },
  { id: 'utility', label: '水電瓦斯', bucket: '固定', color: 'var(--c-bud-fixed)' },
  { id: 'subscription', label: '訂閱服務', bucket: '固定', color: 'var(--c-bud-fixed)' },
  { id: 'shopping', label: '購物', bucket: '彈性', color: 'var(--c-bud-flex)' },
  { id: 'travel', label: '旅遊', bucket: '彈性', color: 'var(--c-bud-flex)' },
  { id: 'health', label: '醫療', bucket: '生活', color: 'var(--c-bud-living)' },
  { id: 'other', label: '其他', bucket: '彈性', color: 'var(--c-bud-flex)' },
];

const sampleTransactions = [
  { id: 1, date: '04/03', merchant: 'Starbucks 信義店', amount: 165, cat: 'food', conf: 0.98, auto: true, rule: '已記住規則' },
  { id: 2, date: '04/03', merchant: '全聯福利中心', amount: 1842, cat: 'grocery', conf: 0.95, auto: true },
  { id: 3, date: '04/04', merchant: '台灣電力公司', amount: 1284, cat: 'utility', conf: 0.99, auto: true, rule: '已記住規則' },
  { id: 4, date: '04/05', merchant: 'Spotify Premium', amount: 149, cat: 'subscription', conf: 0.99, auto: true, rule: '訂閱' },
  { id: 5, date: '04/06', merchant: '悠遊卡自動加值', amount: 500, cat: 'transit', conf: 0.97, auto: true },
  { id: 6, date: '04/07', merchant: 'UberEats', amount: 285, cat: 'food', conf: 0.96, auto: true },
  { id: 7, date: '04/08', merchant: 'iHerb Inc.', amount: 1450, cat: 'health', conf: 0.91, auto: true },
  { id: 8, date: '04/09', merchant: '家樂福 內湖', amount: 2384, cat: 'grocery', conf: 0.94, auto: true },
  { id: 9, date: '04/10', merchant: 'Netflix', amount: 270, cat: 'subscription', conf: 0.99, auto: true },
  { id: 20, date: '04/11', merchant: 'NTU TIMS Coffee', amount: 320, cat: null, suggest: 'food', conf: 0.62, auto: false, hint: '新商家 · 推測為餐飲' },
  { id: 21, date: '04/12', merchant: 'Klook 體驗預訂', amount: 4280, cat: null, suggest: 'travel', conf: 0.71, auto: false, hint: '可能為旅遊或彈性' },
  { id: 22, date: '04/14', merchant: 'PChome 24h', amount: 1890, cat: null, suggest: 'shopping', conf: 0.74, auto: false, hint: '依商品種類可重分類' },
  { id: 23, date: '04/16', merchant: '日本郵便 EMS', amount: 2150, cat: null, suggest: 'other', conf: 0.55, auto: false, hint: '無歷史紀錄' },
  { id: 24, date: '04/18', merchant: '誠品 信義', amount: 680, cat: null, suggest: 'shopping', conf: 0.68, auto: false, hint: '可能為書籍或購物' },
];

function formatMoney(value) {
  return value.toLocaleString('en-US');
}

function Money({ value, prefix = 'NT$', size = 28, weight = 500, mute = false, signed = false, hidden = false, color }) {
  const sign = signed ? (value > 0 ? '+' : value < 0 ? '-' : '') : '';
  const display = hidden ? '¥¥¥¥¥' : formatMoney(Math.abs(value));
  return (
    <span className="tnum money" style={{ '--money-size': `${size}px`, '--money-weight': weight, color: color || (mute ? 'var(--c-text-3)' : 'var(--c-text)') }}>
      {sign && <span className="money-sign">{sign}</span>}
      <span className="money-prefix">{prefix}</span>
      {display}
    </span>
  );
}

function Progress({ value, target, max, tone = 'default', height = 6, showMarker = true }) {
  const pct = Math.min(100, (value / max) * 100);
  const targetPct = target == null ? null : (target / max) * 100;
  return (
    <div className="progress" style={{ height }}>
      <span className={`progress-fill ${tone}`} style={{ width: `${pct}%` }} />
      {showMarker && targetPct != null && <span className="progress-marker" style={{ left: `${targetPct}%` }} />}
    </div>
  );
}

function Sparkline({ data, w = 290, h = 62 }) {
  const min = Math.min(...data);
  const max = Math.max(...data);
  const span = max - min || 1;
  const px = (i) => (i / (data.length - 1)) * w;
  const py = (v) => h - ((v - min) / span) * (h - 4) - 2;
  const path = data.map((v, i) => `${i === 0 ? 'M' : 'L'} ${px(i).toFixed(1)} ${py(v).toFixed(1)}`).join(' ');
  return (
    <svg width={w} height={h} className="sparkline" viewBox={`0 0 ${w} ${h}`}>
      <path d={`${path} L ${w} ${h} L 0 ${h} Z`} className="sparkline-area" />
      <path d={path} className="sparkline-line" />
      <circle cx={px(data.length - 1)} cy={py(data[data.length - 1])} r="2.5" className="sparkline-dot" />
    </svg>
  );
}

function Donut({ segments, size = 140, thickness = 14, center, sub }) {
  const total = segments.reduce((sum, item) => sum + item.value, 0);
  const radius = size / 2 - thickness / 2;
  const circumference = 2 * Math.PI * radius;
  let offset = 0;
  return (
    <div className="donut" style={{ width: size, height: size }}>
      <svg width={size} height={size} viewBox={`0 0 ${size} ${size}`}>
        <circle cx={size / 2} cy={size / 2} r={radius} className="donut-track" strokeWidth={thickness} />
        {segments.map((segment) => {
          const len = (segment.value / total) * circumference;
          const dashOffset = -offset;
          offset += len;
          return (
            <circle
              key={segment.label}
              cx={size / 2}
              cy={size / 2}
              r={radius}
              className="donut-segment"
              stroke={segment.color}
              strokeWidth={thickness}
              strokeDasharray={`${Math.max(0, len - 1.5)} ${circumference - len + 1.5}`}
              strokeDashoffset={dashOffset}
            />
          );
        })}
      </svg>
      <div className="donut-center">
        <strong>{center}</strong>
        <span>{sub}</span>
      </div>
    </div>
  );
}

function StackedBar({ segments, height = 10 }) {
  const total = segments.reduce((sum, item) => sum + item.value, 0);
  return (
    <div className="stacked-bar" style={{ height }}>
      {segments.map((segment) => (
        <span key={segment.label} title={segment.label} style={{ flex: segment.value / total, background: segment.color }} />
      ))}
    </div>
  );
}

function Card({ title, eyebrow, action, children, className = '', style }) {
  return (
    <section className={`card ${className}`} style={style}>
      {(title || eyebrow || action) && (
        <header className="card-header">
          <div>
            {eyebrow && <span className="eyebrow">{eyebrow}</span>}
            {title && <h2>{title}</h2>}
          </div>
          {action}
        </header>
      )}
      <div className="card-body">{children}</div>
    </section>
  );
}

function ChromeWindow({ page, children }) {
  const meta = {
    dashboard: ['總覽 — Northhaven', 'northhaven.app/'],
    import: ['審核分類 — Northhaven', 'northhaven.app/transactions/import?card=•••4527'],
    budget: ['本月預算 — Northhaven', 'northhaven.app/budget'],
    portfolio: ['投資配置 — Northhaven', 'northhaven.app/portfolio/allocation'],
    onboarding: ['首次設定 — Northhaven', 'northhaven.app/onboarding/risk-questionnaire'],
  }[page] || ['總覽 — Northhaven', 'northhaven.app/'];

  return (
    <div className="chrome-window">
      <div className="chrome-tabs">
        <div className="traffic" aria-hidden="true"><span /><span /><span /></div>
        <div className="tab active"><span className="tab-favicon" />{meta[0]}</div>
        <div className="tab">Gmail</div>
        <div className="tab">Notion</div>
      </div>
      <div className="chrome-toolbar">
        <span className="toolbar-dot" />
        <div className="url-bar"><ShieldCheck size={13} />{meta[1]}</div>
        <span className="toolbar-dot" />
      </div>
      <div className="chrome-content">{children}</div>
    </div>
  );
}

function Sidebar({ active, onNavigate, hidden, onToggleHidden }) {
  return (
    <aside className="sidebar">
      <div className="brand">
        <span className="brand-mark">N</span>
        <span><strong>Northhaven</strong><small>淨值駕駛艙</small></span>
      </div>
      <span className="eyebrow nav-label">主要</span>
      <nav className="nav-list">
        {navItems.map(({ id, icon: IconCmp, label, badge }) => (
          <button key={id} className={`nav-item ${active === id ? 'active' : ''}`} onClick={() => onNavigate(id)}>
            <IconCmp size={16} strokeWidth={1.5} />
            <span>{label}</span>
            {badge && <em>{badge}</em>}
          </button>
        ))}
      </nav>
      <div className="sidebar-spacer" />
      <span className="eyebrow nav-label">帳戶</span>
      <button className={`nav-item ${active === 'settings' ? 'active' : ''}`} onClick={() => onNavigate('dashboard')}>
        <Settings size={16} strokeWidth={1.5} />
        <span>設定 Settings</span>
      </button>
      <div className="profile">
        <span className="avatar">JL</span>
        <span><strong>林佳欣</strong><small>Pro · 自由方案</small></span>
        <button className="icon-button" onClick={onToggleHidden} title={hidden ? '顯示金額' : '隱藏金額'} aria-label={hidden ? '顯示金額' : '隱藏金額'}>
          {hidden ? <EyeOff size={15} /> : <Eye size={15} />}
        </button>
      </div>
    </aside>
  );
}

function SavingsBlock({ hidden }) {
  const rate = 28.4;
  const target = 30;
  const income = 132000;
  const saved = 37500;
  const pct = Math.min(100, (rate / target) * 100);
  return (
    <section className="card savings-card">
      <div className="split">
        <div>
          <span className="eyebrow">本月儲蓄率 · Savings Rate</span>
          <p className="muted">4 月 1 日 — 4 月 26 日 · 還剩 4 天</p>
        </div>
        <p className="muted">達成度 <strong className="tnum">{pct.toFixed(0)}%</strong></p>
      </div>
      <div className="hero-number">
        <span className="tnum">{hidden ? '——' : rate}<small>%</small></span>
        <p>目標 {target}%<br /><strong>{hidden ? '——' : `${(rate - target).toFixed(1)}pp`} vs 目標</strong></p>
      </div>
      <Progress value={rate} target={target} max={50} height={4} />
      <div className="stat-row">
        <div><span className="eyebrow">本月收入</span><Money value={income} size={18} hidden={hidden} /><small>稅後</small></div>
        <div><span className="eyebrow">已支出</span><Money value={income - saved} size={18} hidden={hidden} /><small>至今</small></div>
        <div><span className="eyebrow">已儲蓄</span><Money value={saved} size={18} hidden={hidden} /><small>存入投資</small></div>
      </div>
    </section>
  );
}

function NetWorthBlock({ hidden }) {
  return (
    <section className="card networth-card">
      <div className="split">
        <span className="eyebrow">淨資產 · Net Worth</span>
        <span className="muted">過去 6 個月</span>
      </div>
      <Money value={2450000} size={32} hidden={hidden} />
      <div className="delta"><ArrowUp size={12} />{hidden ? '——' : 'NT$ 85,000'}<span>{hidden ? '——' : '+3.5%'} 較上月</span></div>
      <Sparkline data={[2280000, 2310000, 2295000, 2360000, 2365000, 2450000]} />
      <div className="axis"><span>11 月</span><span>12 月</span><span>1 月</span><span>2 月</span><span>3 月</span><span>4 月</span></div>
    </section>
  );
}

function BudgetBlock({ hidden }) {
  const cats = [
    { name: '固定支出', en: 'Fixed', used: 38400, budget: 42000, color: 'var(--c-bud-fixed)' },
    { name: '生活預算', en: 'Living', used: 23800, budget: 28000, color: 'var(--c-bud-living)' },
    { name: '彈性預算', en: 'Flex', used: 8200, budget: 14000, color: 'var(--c-bud-flex)' },
  ];
  return (
    <Card title="本月預算" eyebrow="BUDGET" className="span-6" action={<span className="muted">剩餘 4 天</span>}>
      <div className="budget-list">
        {cats.map((cat) => {
          const pct = (cat.used / cat.budget) * 100;
          const tone = pct >= 90 ? 'warn' : pct >= 75 ? 'near' : 'default';
          return (
            <div key={cat.name} className="budget-line">
              <div className="split">
                <p><i style={{ background: cat.color }} />{cat.name}<small>{cat.en}</small></p>
                <p><Money value={cat.used} size={12} prefix="" hidden={hidden} /><span className="muted"> / </span><Money value={cat.budget} size={12} prefix="" mute hidden={hidden} /></p>
              </div>
              <Progress value={cat.used} max={cat.budget} height={4} tone={tone} showMarker={false} />
              <div className="axis"><span>{pct.toFixed(0)}% 已使用</span><span>剩餘 4 天 · 日均可用 NT$ {hidden ? '——' : Math.round((cat.budget - cat.used) / 4).toLocaleString()}</span></div>
            </div>
          );
        })}
      </div>
    </Card>
  );
}

function AllocationBlock({ hidden }) {
  const segments = [
    { label: '股票 ETF', value: 58, color: 'var(--c-cat-equity)', target: 60 },
    { label: '債券', value: 22, color: 'var(--c-cat-bond)', target: 25 },
    { label: '現金', value: 14, color: 'var(--c-cat-cash)', target: 10 },
    { label: '加密', value: 6, color: 'var(--c-cat-crypto)', target: 5 },
  ];
  return (
    <Card title="投資配置" eyebrow="PORTFOLIO" className="span-6" action={<span className="muted">偏離度 4.2%</span>}>
      <div className="allocation-mini">
        <Donut segments={segments} center={hidden ? '——' : '2.45M'} sub="淨值" />
        <div className="allocation-legend">
          {segments.map((segment) => {
            const drift = segment.value - segment.target;
            return (
              <p key={segment.label}>
                <i style={{ background: segment.color }} /> <span>{segment.label}</span>
                <strong className="tnum">{segment.value}%</strong>
                <small>目標 {segment.target}%</small>
                <em>{drift > 0 ? '+' : ''}{drift}pp</em>
              </p>
            );
          })}
        </div>
      </div>
    </Card>
  );
}

function HealthBadge({ tone }) {
  const map = {
    structural: ['diamond', '結構'],
    warn: ['triangle', '檢視'],
    edu: ['square', '建議'],
    info: ['dot', '資訊'],
  }[tone];
  return <span className={`health-badge ${tone}`}><i className={map[0]} />{map[1]}</span>;
}

function HealthBlock() {
  const items = [
    { tone: 'structural', title: '股票部位偏離目標 4pp', body: '可考慮在下次補倉時調整比例。', cta: '查看配置' },
    { tone: 'edu', title: '永豐 ATM 卡帳單即將出', body: '預估 NT$ 24,800 · 4 月 30 日結帳 · 5 月 15 日繳款', cta: '預先匯入' },
    { tone: 'info', title: '緊急金已達 6 個月支出', body: '本月新增儲蓄將直接進入投資配置。' },
  ];
  return (
    <Card title="值得檢視" eyebrow="ATTENTION" className="span-8" action={<button className="text-button">全部 <ChevronRight size={12} /></button>}>
      <div className="health-list">
        {items.map((item) => (
          <div key={item.title}>
            <HealthBadge tone={item.tone} />
            <p><strong>{item.title}</strong><span>{item.body}</span></p>
            {item.cta && <button className="outline-small">{item.cta}</button>}
          </div>
        ))}
      </div>
    </Card>
  );
}

function StatementBlock({ hidden, onImport }) {
  return (
    <Card title="本期信用卡" eyebrow="STATEMENT" className="span-4">
      <div className="statement-card">
        <div className="split"><span>永豐 SPORT</span><span className="tnum">•••• 4527</span></div>
        <Money value={24800} size={22} hidden={hidden} />
        <p className="muted">預估本期帳單</p>
        <p className="statement-dates"><span>結帳 <b>4/30</b></span><span>繳款 <b>5/15</b></span></p>
      </div>
      <button className="full-button" onClick={onImport}><Upload size={14} />匯入本期帳單</button>
      <p className="muted body-note">上次匯入到 3 月帳單。匯入後將更新本月生活與彈性預算。</p>
    </Card>
  );
}

function Dashboard({ hidden, onNavigate }) {
  return (
    <div className="page">
      <header className="page-heading">
        <div><span className="eyebrow">星期日 · 4 月 26 日</span><h1>晚安,佳欣 — <span>這個月過得很穩。</span></h1></div>
        <div className="heading-actions">
          <button className="outline-button">2026 · 4 月 <ChevronDown size={13} /></button>
          <button className="primary-button"><Plus size={13} />記一筆</button>
        </div>
      </header>
      <div className="dashboard-grid">
        <SavingsBlock hidden={hidden} />
        <NetWorthBlock hidden={hidden} />
        <BudgetBlock hidden={hidden} />
        <AllocationBlock hidden={hidden} />
        <HealthBlock />
        <StatementBlock hidden={hidden} onImport={() => onNavigate('import')} />
      </div>
      <footer className="page-footer"><span>本資訊僅供參考,不構成投資建議。</span><span>最後同步 · 26 Apr 19:42</span></footer>
    </div>
  );
}

function CategoryPill({ catId, onClick, selected }) {
  const cat = categories.find((item) => item.id === catId);
  if (!cat) return <button className="cat-pill empty" onClick={onClick}>未分類 <ChevronDown size={10} /></button>;
  return (
    <button className={`cat-pill ${selected ? 'selected' : ''}`} onClick={onClick} style={{ '--cat': cat.color }}>
      {cat.label}
      {onClick && <ChevronDown size={10} />}
    </button>
  );
}

function ConfidenceMeter({ value }) {
  const pct = Math.round(value * 100);
  return <span className="confidence"><i style={{ width: `${pct}%` }} />{pct}%</span>;
}

function CategoryPicker({ onPick, onClose }) {
  return (
    <div className="category-picker">
      <span className="eyebrow">選擇分類</span>
      {['固定', '生活', '彈性'].map((bucket) => (
        <div key={bucket}>
          <small>{bucket}預算</small>
          {categories.filter((cat) => cat.bucket === bucket).map((cat) => (
            <button key={cat.id} onClick={() => { onPick(cat.id); onClose(); }}>
              <i style={{ background: cat.color }} />{cat.label}
            </button>
          ))}
        </div>
      ))}
    </div>
  );
}

function TransactionRow({ txn, accepted, rejected, onAccept, onReject, onPickCat }) {
  const cat = txn.cat || txn.suggest;
  return (
    <div className={`txn-row ${accepted ? 'accepted' : ''} ${rejected ? 'rejected' : ''}`}>
      <span className="tnum muted">{txn.date}</span>
      <p><strong>{txn.merchant}</strong>{txn.hint && <small>{txn.hint}</small>}{txn.rule && <small className="rule"><Check size={10} />{txn.rule}</small>}</p>
      <CategoryPill catId={cat} onClick={onPickCat} selected={accepted} />
      <ConfidenceMeter value={txn.conf} />
      <strong className="tnum amount">NT$ {formatMoney(txn.amount)}</strong>
      {txn.auto ? (
        <span className="muted action-label">{accepted ? '已確認' : '自動分類'}</span>
      ) : (
        <span className="row-actions">
          <button className={accepted ? 'active' : ''} onClick={onAccept} aria-label="接受建議"><Check size={13} /></button>
          <button onClick={onReject} aria-label="暫不處理"><MoreHorizontal size={13} /></button>
        </span>
      )}
    </div>
  );
}

function ImportReview() {
  const [transactions, setTransactions] = useState(sampleTransactions);
  const [accepted, setAccepted] = useState(new Set([1, 2, 3, 4, 5, 6, 7, 8, 9]));
  const [rejected, setRejected] = useState(new Set());
  const [pickerFor, setPickerFor] = useState(null);
  const [autoExpanded, setAutoExpanded] = useState(false);
  const auto = transactions.filter((item) => item.auto);
  const review = transactions.filter((item) => !item.auto);
  const total = transactions.reduce((sum, item) => sum + item.amount, 0);
  const reviewAccepted = [...accepted].filter((id) => review.some((item) => item.id === id)).length;

  const toggleAccepted = (id) => {
    setAccepted((prev) => {
      const next = new Set(prev);
      if (next.has(id)) next.delete(id); else next.add(id);
      return next;
    });
    setRejected((prev) => {
      const next = new Set(prev);
      next.delete(id);
      return next;
    });
  };

  const toggleRejected = (id) => {
    setRejected((prev) => {
      const next = new Set(prev);
      if (next.has(id)) next.delete(id); else next.add(id);
      return next;
    });
  };

  const setCat = (id, catId) => {
    setTransactions((prev) => prev.map((item) => item.id === id ? { ...item, cat: catId, suggest: catId } : item));
    setAccepted((prev) => new Set(prev).add(id));
  };

  return (
    <div className="page">
      <div className="steps"><span>1. 選擇卡片</span><i /> <span>2. 上傳檔案</span><i /> <span>3. 解析</span><i /> <strong>4. 審核分類</strong><i /> <span>5. 確認寫入</span></div>
      <header className="page-heading">
        <div><span className="eyebrow">永豐 SPORT · •••• 4527</span><h1>審核 4 月份分類</h1><p>共解析 {transactions.length} 筆 · 總額 NT$ {formatMoney(total)} · 待你確認的有 <strong>{review.length} 筆</strong></p></div>
        <div className="heading-actions"><button className="outline-button">儲存草稿</button><button className="primary-button">確認寫入 {accepted.size} 筆 <ChevronRight size={13} /></button></div>
      </header>
      <section className="summary-band">
        <div><span className="eyebrow">已自動分類</span><strong>{auto.length}</strong><small>高信心度,可摺疊</small></div>
        <div><span className="eyebrow">待你確認</span><strong>{review.length - reviewAccepted}</strong><small>新商家或低信心度</small></div>
        <div><span className="eyebrow">已確認</span><strong>{accepted.size}</strong><small>共 {transactions.length} 筆中</small></div>
        <div><span className="eyebrow">影響預算</span><strong>L · F</strong><small>生活 +35K · 彈性 +12K</small></div>
      </section>
      <section className="table-section">
        <div className="section-title"><p><strong>待你確認</strong><span>新商家或信心度 &lt; 80%</span></p><span><button className="soft-button" onClick={() => setAccepted(new Set(transactions.map((item) => item.id)))}>全部接受建議</button><button className="outline-small">批次改分類</button></span></div>
        <div className="txn-table">
          <div className="txn-head"><span>日期</span><span>商家 / 描述</span><span>建議分類</span><span>信心度</span><span>金額</span><span>動作</span></div>
          {review.map((txn) => (
            <div key={txn.id} className="row-wrap">
              <TransactionRow txn={txn} accepted={accepted.has(txn.id)} rejected={rejected.has(txn.id)} onAccept={() => toggleAccepted(txn.id)} onReject={() => toggleRejected(txn.id)} onPickCat={() => setPickerFor(pickerFor === txn.id ? null : txn.id)} />
              {pickerFor === txn.id && <CategoryPicker onPick={(catId) => setCat(txn.id, catId)} onClose={() => setPickerFor(null)} />}
            </div>
          ))}
        </div>
      </section>
      <section className="auto-section">
        <button onClick={() => setAutoExpanded(!autoExpanded)}><ChevronRight className={autoExpanded ? 'open' : ''} size={14} /><strong>已自動分類</strong><span>{auto.length} 筆</span><em>高信心度 · 已套用既有規則 · 可隨時展開檢視</em></button>
        {autoExpanded && <div className="txn-table auto">{auto.map((txn) => <TransactionRow key={txn.id} txn={txn} accepted={accepted.has(txn.id)} />)}</div>}
      </section>
      <p className="hint-band"><strong>越用越快</strong> · 你為新商家確認的分類會被記住,下個月遇到同一商家系統會自動分類。</p>
    </div>
  );
}

function BudgetPage({ hidden }) {
  const cats = [
    { name: '固定支出', en: 'Fixed', used: 38400, budget: 42000, color: 'var(--c-bud-fixed)', items: [['房租', 22000, '每月 5 日'], ['電信 + 寬頻', 1390, '每月 12 日'], ['訂閱(Spotify/Netflix/iCloud)', 1018, '已扣'], ['保險', 8500, '每月 18 日'], ['水電瓦斯均攤', 5492, '雙月']] },
    { name: '生活預算', en: 'Living', used: 23800, budget: 28000, color: 'var(--c-bud-living)', items: [['餐飲', 9420], ['生鮮', 7180], ['交通', 4200], ['日用品', 3000]] },
    { name: '彈性預算', en: 'Flex', used: 8200, budget: 14000, color: 'var(--c-bud-flex)', items: [['購物', 4280], ['娛樂', 2120], ['禮品', 1800]] },
  ];
  return (
    <div className="page">
      <header className="page-heading"><div><span className="eyebrow">2026 · 4 月 · 還剩 4 天</span><h1>本月預算</h1></div><div className="heading-actions"><button className="outline-button">歷史月份</button><button className="outline-button">編輯預算</button></div></header>
      <section className="budget-summary">
        <div><span className="eyebrow">稅後月收入</span><Money value={132000} size={26} hidden={hidden} /><small>軟體工程師 · 月薪 + 兼職</small></div>
        <div><span className="eyebrow">已分配支出</span><Money value={84000} size={22} hidden={hidden} /><small>佔收入 64%</small></div>
        <div><span className="eyebrow">儲蓄目標</span><Money value={40000} size={22} hidden={hidden} /><small>目標 30% · 將進入投資配置</small></div>
        <div><span className="eyebrow">本月實際儲蓄率</span><strong className="tnum">{hidden ? '——' : '28.4'}<small>%</small></strong><small>距目標 -1.6pp · 預估月底達 31%</small></div>
      </section>
      <section className="budget-columns">
        {cats.map((cat) => <BudgetColumn key={cat.name} cat={cat} hidden={hidden} />)}
      </section>
      <section className="forward-card">
        <div><span className="eyebrow">向前看 · NEXT MONTH</span><h2>下個月想怎麼分配?</h2><p>本月生活預算還剩 4,200,彈性還剩 5,800。下個月可以考慮把彈性預算下調 2,000、轉入儲蓄,將儲蓄率拉到 31%。要試試看嗎?</p></div>
        <span><button className="primary-button">規劃 5 月預算</button><button className="outline-button">沿用 4 月設定</button></span>
      </section>
    </div>
  );
}

function BudgetColumn({ cat, hidden }) {
  const pct = (cat.used / cat.budget) * 100;
  const remain = cat.budget - cat.used;
  const tone = pct >= 90 ? 'warn' : pct >= 75 ? 'near' : 'default';
  return (
    <div className="budget-column card">
      <header><span style={{ background: cat.color }} /><p><strong>{cat.name}</strong><small>{cat.en}</small></p><em className={tone}>{pct.toFixed(0)}%</em></header>
      <Money value={cat.used} size={22} hidden={hidden} /><span className="muted"> / {hidden ? '——' : formatMoney(cat.budget)}</span>
      <Progress value={cat.used} max={cat.budget} tone={tone} height={4} showMarker={false} />
      <div className="axis"><span>剩 NT$ {hidden ? '——' : formatMoney(remain)}</span><span>日均可用 NT$ {hidden ? '——' : formatMoney(Math.round(remain / 4))}</span></div>
      <ul>{cat.items.map(([name, amount, due]) => <li key={name}><span><strong>{name}</strong>{due && <small>{due}</small>}</span><em>{hidden ? '¥¥¥' : `NT$ ${formatMoney(amount)}`}</em></li>)}</ul>
    </div>
  );
}

function PortfolioPage({ hidden }) {
  const current = [
    { label: '股票 ETF', value: 58, color: 'var(--c-cat-equity)' },
    { label: '債券', value: 22, color: 'var(--c-cat-bond)' },
    { label: '現金', value: 14, color: 'var(--c-cat-cash)' },
    { label: '加密', value: 6, color: 'var(--c-cat-crypto)' },
  ];
  const target = [{ ...current[0], value: 60 }, { ...current[1], value: 25 }, { ...current[2], value: 10 }, { ...current[3], value: 5 }];
  const holdings = [
    ['股票 ETF', 'VTI · Vanguard Total Stock', 720000, 29.4, 'var(--c-cat-equity)'],
    ['股票 ETF', 'VXUS · 國際股票', 408000, 16.6, 'var(--c-cat-equity)'],
    ['股票 ETF', '0050 · 元大台灣 50', 293000, 12.0, 'var(--c-cat-equity)'],
    ['債券', 'BND · 美國公債', 320000, 13.1, 'var(--c-cat-bond)'],
    ['債券', '00679B · 元大美債 20年', 220000, 9.0, 'var(--c-cat-bond)'],
    ['現金', '永豐銀行 · 活期', 245000, 10.0, 'var(--c-cat-cash)'],
    ['現金', '台新 Richart · 數位帳戶', 99000, 4.0, 'var(--c-cat-cash)'],
    ['加密', 'BTC', 145000, 5.9, 'var(--c-cat-crypto)'],
  ];
  return (
    <div className="page">
      <header className="page-heading"><div><span className="eyebrow">投資配置 · ALLOCATION</span><h1>現況 vs 目標</h1><p>風險屬性 · <strong>穩健成長型</strong> · 最後再平衡: 2026 年 1 月 18 日</p></div><button className="outline-button">調整目標配置</button></header>
      <section className="portfolio-hero card">
        <div className="compare-bars">{[['現況', 'CURRENT', current], ['目標', 'TARGET', target]].map(([title, sub, data]) => <div key={title}><div className="split"><strong>{title}</strong><span className="eyebrow">{sub}</span></div><StackedBar segments={data} height={32} /><div className="portfolio-legend">{data.map((item) => <p key={item.label}><i style={{ background: item.color }} />{item.label}<strong>{item.value}%</strong></p>)}</div></div>)}</div>
        <div className="drift-grid">{current.map((item, index) => { const drift = item.value - target[index].value; return <div key={item.label}><p><i style={{ background: item.color }} />{item.label}</p><strong>{drift > 0 ? '+' : drift < 0 ? '-' : '±'}{Math.abs(drift)}<small>pp</small></strong><span>{item.value}% → {target[index].value}%</span></div>; })}</div>
      </section>
      <section className="portfolio-columns">
        <div className="holdings card"><header><div><strong>持有明細</strong><small>共 8 筆 · 總值 NT$ 2,450,000</small></div><button className="outline-small">依類別</button></header>{holdings.map(([cls, name, val, pct, color]) => <div key={name} className="holding-row"><i style={{ background: color }} /><span><strong>{name}</strong><small>{cls}</small></span><em>{pct}%</em><strong>{hidden ? '¥¥¥¥¥' : `NT$ ${formatMoney(val)}`}</strong><b><i style={{ width: `${pct * 2.5}%`, background: color }} /></b></div>)}</div>
        <div className="portfolio-side"><div className="card advice"><span className="eyebrow">補倉建議 · DIRECTIONAL</span><h2>下次補倉時可以這樣分配</h2><p>假設下個月可投入 NT$ 40,000,把比例往目標靠攏的方向是:</p>{[['股票 ETF', 50, 20000, 'var(--c-cat-equity)'], ['債券', 35, 14000, 'var(--c-cat-bond)'], ['現金', 0, 0, 'var(--c-cat-cash)'], ['加密', 15, 6000, 'var(--c-cat-crypto)']].map(([label, pct, val, color]) => <div key={label} className="advice-row"><span><i style={{ background: color }} />{label}</span><b><i style={{ width: `${pct}%`, background: color }} /></b><em>{hidden ? '——' : `${pct}% · ${val / 1000}K`}</em></div>)}<small>本資訊僅供參考,不構成投資建議。系統不指定具體個股或基金,實際買入由你自行決定。</small></div><div className="card concentration"><span><i className="diamond" />單一資產集中度</span><p>VTI 佔總資產 29.4%。一般建議單一個股或 ETF 不超過 20%,但對全市場 ETF 而言此風險較低。</p></div></div>
      </section>
    </div>
  );
}

function OnboardingPage() {
  const [answer, setAnswer] = useState(2);
  const opts = [
    ['不能接受任何虧損,寧可不賺', '保守型 · 重視保本'],
    ['可接受小幅波動,長期穩定為主', '穩健型 · 偏債'],
    ['可接受中等波動以追求合理報酬', '穩健成長型 · 60/40'],
    ['可接受較大波動以追求較高報酬', '成長型 · 偏股'],
    ['高波動高風險也沒問題', '積極型 · 重股'],
  ];
  return (
    <div className="page onboarding-page">
      <div className="onboarding-top"><span>3 / 8</span><i><b /></i><span>風險屬性 · 第 3 題</span><button>稍後再說 →</button></div>
      <main className="question-card"><span className="eyebrow">RISK PROFILE</span><h1>假設你的投資組合在一年內<br />下跌 20%,你的反應是?</h1><p>這題沒有正確答案。我們用你的選擇來建議目標配置 — 之後可以隨時調整。</p><div>{opts.map(([label, desc], index) => <button key={label} className={answer === index ? 'selected' : ''} onClick={() => setAnswer(index)}><i>{answer === index && <b />}</i><span><strong>{label}</strong><small>{desc}</small></span><em>{String.fromCharCode(65 + index)}</em></button>)}</div><footer><button className="outline-button">← 上一題</button><button className="primary-button">繼續 <ChevronRight size={13} /></button></footer></main>
    </div>
  );
}

function PageRouter({ page, hidden, onNavigate }) {
  if (page === 'import') return <ImportReview />;
  if (page === 'budget') return <BudgetPage hidden={hidden} />;
  if (page === 'portfolio') return <PortfolioPage hidden={hidden} />;
  if (page === 'onboarding') return <OnboardingPage />;
  return <Dashboard hidden={hidden} onNavigate={onNavigate} />;
}

function App() {
  const [page, setPage] = useState('dashboard');
  const [hidden, setHidden] = useState(false);
  const [accent, setAccent] = useState('slate');
  const accentStyle = useMemo(() => ACCENTS[accent], [accent]);
  const active = page === 'import' ? 'transactions' : page;
  const navigate = (id) => {
    if (id === 'transactions') setPage('import');
    else if (['dashboard', 'budget', 'portfolio'].includes(id)) setPage(id);
  };

  return (
    <div className="canvas" style={accentStyle}>
      <ChromeWindow page={page}>
        <div className="app-shell">
          {page !== 'onboarding' && <Sidebar active={active} onNavigate={navigate} hidden={hidden} onToggleHidden={() => setHidden((value) => !value)} />}
          <main className="app-main"><PageRouter page={page} hidden={hidden} onNavigate={setPage} /></main>
        </div>
      </ChromeWindow>
      <div className="tweaks" aria-label="Design tweaks">
        <span><SlidersHorizontal size={14} /> Tweaks</span>
        <label>頁面<select value={page} onChange={(event) => setPage(event.target.value)}><option value="dashboard">Dashboard 總覽</option><option value="import">帳單匯入審核</option><option value="budget">本月預算</option><option value="portfolio">投資配置</option><option value="onboarding">風險問卷</option></select></label>
        <label>主色<select value={accent} onChange={(event) => setAccent(event.target.value)}><option value="slate">slate</option><option value="pine">pine</option><option value="ink">ink</option><option value="amber">amber</option></select></label>
        <button onClick={() => setHidden((value) => !value)}>{hidden ? '顯示金額' : '隱私模式'}</button>
      </div>
    </div>
  );
}

createRoot(document.getElementById('root')).render(<App />);
