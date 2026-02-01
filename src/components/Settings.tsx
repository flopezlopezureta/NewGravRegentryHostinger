
import React, { useState, useEffect } from 'react';
import { User } from '../types';
import ProfileSettings from './ProfileSettings';

interface SettingsProps {
    user: User;
}

const Settings: React.FC<SettingsProps> = ({ user }) => {
    const [activeTab, setActiveTab] = useState<'security' | 'display'>('security');
    const [dashboardMode, setDashboardMode] = useState<'normal' | 'grafana'>(() => {
        return (localStorage.getItem('selcom_dashboard_mode') as 'normal' | 'grafana') || 'normal';
    });

    const handleModeChange = (mode: 'normal' | 'grafana') => {
        setDashboardMode(mode);
        localStorage.setItem('selcom_dashboard_mode', mode);
        // Podemos disparar un evento o simplemente confiar en que el usuario refrescará/navegará
    };

    return (
        <div className="max-w-4xl mx-auto py-8 animate-in fade-in slide-in-from-bottom-4 duration-700">
            <div className="mb-10">
                <h2 className="text-3xl font-black text-white uppercase tracking-tighter">Configuración del Sistema</h2>
                <p className="text-slate-500 text-[10px] font-black uppercase tracking-[0.3em] mt-1">Panel de Control de Usuario</p>
            </div>

            <div className="flex gap-4 mb-8 bg-slate-900/50 p-1.5 rounded-2xl border border-slate-800/50 w-fit">
                <button
                    onClick={() => setActiveTab('security')}
                    className={`px-6 py-2.5 rounded-xl text-[10px] font-black uppercase tracking-widest transition-all ${activeTab === 'security'
                            ? 'bg-cyan-600 text-white shadow-lg shadow-cyan-900/20'
                            : 'text-slate-500 hover:text-slate-300'
                        }`}
                >
                    Seguridad de Acceso
                </button>
                <button
                    onClick={() => setActiveTab('display')}
                    className={`px-6 py-2.5 rounded-xl text-[10px] font-black uppercase tracking-widest transition-all ${activeTab === 'display'
                            ? 'bg-cyan-600 text-white shadow-lg shadow-cyan-900/20'
                            : 'text-slate-500 hover:text-slate-300'
                        }`}
                >
                    Preferencias de Vista
                </button>
            </div>

            <div className="transition-all duration-500">
                {activeTab === 'security' ? (
                    <ProfileSettings user={user} />
                ) : (
                    <div className="bg-[#1e293b] rounded-[2.5rem] border border-slate-800 shadow-2xl p-10">
                        <div className="flex items-center gap-6 mb-10">
                            <div className="w-16 h-16 bg-slate-900 rounded-2xl flex items-center justify-center text-cyan-400 border border-slate-800 shadow-inner">
                                <svg className="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M9.75 17L9 21h6l-.75-4M3 13h18M5 17h14a2 2 0 002-2V5a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z" />
                                </svg>
                            </div>
                            <div>
                                <h3 className="text-xl font-bold text-white uppercase tracking-tight">Estilo del Dashboard</h3>
                                <p className="text-slate-500 text-[10px] font-black uppercase tracking-widest mt-1">Selecciona cómo visualizar tus datos</p>
                            </div>
                        </div>

                        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                            <button
                                onClick={() => handleModeChange('normal')}
                                className={`p-8 rounded-[2rem] border-2 transition-all text-left flex flex-col gap-4 group ${dashboardMode === 'normal'
                                        ? 'border-cyan-500 bg-cyan-500/5'
                                        : 'border-slate-800 bg-slate-900/40 hover:border-slate-700'
                                    }`}
                            >
                                <div className={`w-12 h-12 rounded-xl flex items-center justify-center transition-colors ${dashboardMode === 'normal' ? 'bg-cyan-500 text-white' : 'bg-slate-800 text-slate-500'
                                    }`}>
                                    <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M4 6a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2H6a2 2 0 01-2-2V6zM14 6a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2h-2a2 2 0 01-2-2V6zM4 16a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2H6a2 2 0 01-2-2v-2zM14 16a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2h-2a2 2 0 01-2-2v-2z" />
                                    </svg>
                                </div>
                                <div>
                                    <h4 className="text-white font-bold uppercase text-sm">Vista Normal</h4>
                                    <p className="text-slate-500 text-xs mt-1">Interfaz moderna nativa con tarjetas dinámicas y sparklines rápidas.</p>
                                </div>
                                {dashboardMode === 'normal' && (
                                    <span className="text-cyan-500 text-[10px] font-black uppercase tracking-widest mt-auto">Seleccionado</span>
                                )}
                            </button>

                            <button
                                onClick={() => handleModeChange('grafana')}
                                className={`p-8 rounded-[2rem] border-2 transition-all text-left flex flex-col gap-4 group ${dashboardMode === 'grafana'
                                        ? 'border-orange-500 bg-orange-500/5'
                                        : 'border-slate-800 bg-slate-900/40 hover:border-slate-700'
                                    }`}
                            >
                                <div className={`w-12 h-12 rounded-xl flex items-center justify-center transition-colors ${dashboardMode === 'grafana' ? 'bg-orange-500 text-white' : 'bg-slate-800 text-slate-500'
                                    }`}>
                                    <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M7 12l3-3 3 3 4-4M8 21l4-4 4 4M3 4h18M4 4h16v12a1 1 0 01-1 1H5a1 1 0 01-1-1V4z" />
                                    </svg>
                                </div>
                                <div>
                                    <h4 className="text-white font-bold uppercase text-sm">Vista Grafana</h4>
                                    <p className="text-slate-500 text-xs mt-1">Dashboards analíticos avanzados integrados para análisis histórico profundo.</p>
                                </div>
                                {dashboardMode === 'grafana' && (
                                    <span className="text-orange-500 text-[10px] font-black uppercase tracking-widest mt-auto">Seleccionado</span>
                                )}
                            </button>
                        </div>

                        <div className="mt-10 p-6 bg-slate-900/40 rounded-3xl border border-slate-800/50">
                            <p className="text-slate-500 text-[10px] font-medium leading-relaxed italic">
                                * El cambio de modo de vista afectará a la visualización principal del dashboard y al detalle de los activos.
                            </p>
                        </div>
                    </div>
                )}
            </div>
        </div>
    );
};

export default Settings;
