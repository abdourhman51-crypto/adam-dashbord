import "./Header.css";

interface HeaderProps {
  onOpenMenu: () => void;
}

export function Header({ onOpenMenu }: HeaderProps) {
  return (
    <header className="header">
      <a className="header__brand" href="#" aria-label="LUXELS — accueil">
        <span className="header__wordmark display">LUXELS</span>
        <span className="header__tm" aria-hidden="true">™</span>
      </a>

      <button className="header__menu-btn" onClick={onOpenMenu} aria-label="Ouvrir le menu">
        <span className="header__menu-label label">Menu</span>
        <span className="header__menu-lines" aria-hidden="true">
          <span />
          <span />
        </span>
      </button>
    </header>
  );
}
