
import React from 'react';
import { ViewMode, UserRole } from '../types';

interface SidebarProps {
  currentView: ViewMode;
  userRole: UserRole;
  companyId?: string;
  onViewChange: (view: ViewMode) => void;
  isOpen: boolean;
  onClose: () => void;
  onLogout: () => void;
}

const Sidebar: React.FC<SidebarProps> = ({ currentView, userRole, companyId, onViewChange, isOpen, onClose, onLogout }) => {
  const handleItemClick = (id: string) => {
    onViewChange(id as ViewMode);
    if (window.innerWidth < 1024) onClose();
  };

  const getMenuItems = () => {
    const items = [
      { id: 'dashboard', label: 'Panel Principal', icon: 'M4 6a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2H6a2 2 0 01-2-2V6zM14 6a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2h-2a2 2 0 01-2-2V6zM4 16a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2H6a2 2 0 01-2-2v-2zM14 16a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2h-2a2 2 0 01-2-2v-2z' },
      { id: 'devices', label: 'Dispositivos', icon: 'M9 3v2m6-2v2M9 19v2m6-2v2M5 9H3m2 6H3m18-6h-2m2 6h-2M7 19h10a2 2 0 002-2V7a2 2 0 00-2-2H7a2 2 0 00-2 2v10a2 2 0 002 2z' },
    ];

    if (userRole === 'admin') {
      items.push({ id: 'companies', label: 'Empresas/Clientes', icon: 'M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4' });
    }

    if (userRole === 'admin' || userRole === 'client') {
      items.push({ id: 'users', label: 'Gestión Usuarios', icon: 'M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z' });
    }

    return items;
  };

  return (
    <>
      {isOpen && <div className="fixed inset-0 bg-black/60 backdrop-blur-sm z-[60] lg:hidden" onClick={onClose} />}
      <aside className={`fixed lg:sticky top-0 left-0 z-[70] h-screen w-72 bg-[#030712] border-r border-slate-800/50 flex flex-col transition-transform duration-300 ease-in-out ${isOpen ? 'translate-x-0' : '-translate-x-full lg:translate-x-0 shadow-2xl lg:shadow-none'}`}>
        <div className="p-8 pb-4 flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="w-12 h-12 bg-cyan-500 rounded-2xl flex items-center justify-center text-[#0f172a] shadow-[0_0_20px_rgba(6,182,212,0.4)]">
              <span className="brand-logo text-2xl">S</span>
            </div>
            <div className="flex flex-col">
              <span className="text-white brand-logo text-sm leading-tight">Selcom</span>
              <span className="text-cyan-500 font-black text-[10px] uppercase tracking-[0.2em]">IoT Cloud</span>
            </div>
          </div>
        </div>

        <div className="px-6 py-6">
          <div className="p-4 bg-slate-900/40 rounded-2xl border border-slate-800/50 backdrop-blur-sm">
            <p className="text-slate-500 text-[8px] font-black uppercase tracking-widest mb-1 shadow-sm">Contexto de Operación</p>
            <p className="text-white text-[11px] font-bold uppercase truncate tracking-wider">
              {userRole === 'admin' ? 'Consola de Control Global' : companyId || 'Identificando...'}
            </p>
          </div>
        </div>

        <nav className="flex-1 px-4 space-y-1.5 overflow-y-auto custom-scrollbar">
          {getMenuItems().map((item) => (
            <button
              key={item.id}
              onClick={() => handleItemClick(item.id)}
              className={`w-full flex items-center gap-4 px-4 py-3.5 rounded-2xl font-bold text-xs uppercase tracking-wider transition-all duration-200 group ${currentView === item.id
                  ? 'bg-cyan-500/10 text-cyan-400 border border-cyan-500/20 shadow-[0_0_15px_rgba(6,182,212,0.1)]'
                  : 'text-slate-500 hover:bg-slate-800/40 hover:text-slate-300 border border-transparent'
                }`}
            >
              <svg
                className={`w-5 h-5 transition-transform duration-300 ${currentView === item.id ? 'scale-110' : 'group-hover:scale-110'}`}
                fill="none"
                stroke="currentColor"
                viewBox="0 0 24 24"
              >
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d={item.icon}></path>
              </svg>
              {item.label}
            </button>
          ))}
        </nav>

        <div className="p-6 border-t border-slate-800/50 bg-slate-900/20">
          <button
            onClick={onLogout}
            className="flex items-center gap-4 text-slate-500 hover:text-rose-400 group transition-all duration-300 w-full px-4 py-3 rounded-2xl hover:bg-rose-500/5"
          >
            <div className="p-2 bg-slate-800/50 rounded-lg group-hover:bg-rose-500/10 transition-colors">
              <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1"></path>
              </svg>
            </div>
            <span className="text-[11px] font-black uppercase tracking-widest">Finalizar Sesión</span>
          </button>
        </div>
      </aside>
    </>
  );
};

export default Sidebar;
