
import React, { useMemo } from 'react';
import { Device, User } from '../types';

interface DashboardProps {
  user: User;
  devices: Device[];
  onSelectDevice: (device: Device) => void;
}

const Dashboard: React.FC<DashboardProps> = ({ user, devices, onSelectDevice }) => {
  const stats = useMemo(() => {
    if (!Array.isArray(devices)) {
      return { total: '00', online: '00', offline: '00' };
    }
    const total = devices.length;
    const online = devices.filter(d => d.status === 'online').length;
    const offline = devices.filter(d => d.status === 'offline').length;
    return {
      total: total.toString().padStart(2, '0'),
      online: online.toString().padStart(2, '0'),
      offline: offline.toString().padStart(2, '0'),
    };
  }, [devices]);

  const SummaryCard = ({ icon, label, value, colorClass }: any) => (
    <div className="bg-slate-900/40 backdrop-blur-md p-8 rounded-[2.5rem] border border-slate-800/50 flex items-center gap-6 group hover:border-cyan-500/30 transition-all duration-300 shadow-lg">
      <div className={`p-4 rounded-2xl ${colorClass} group-hover:scale-110 group-hover:rotate-3 transition-all duration-300 shadow-inner`}>{icon}</div>
      <div>
        <p className="text-slate-500 text-[9px] font-black uppercase tracking-[0.2em] mb-1.5 opacity-80">{label}</p>
        <div className="flex items-baseline gap-1">
          <p className="text-white text-4xl font-black tracking-tighter brand-logo">{value}</p>
          <span className="w-1.5 h-1.5 rounded-full bg-cyan-500/20"></span>
        </div>
      </div>
    </div>
  );

  return (
    <div className="space-y-12 animate-in fade-in slide-in-from-bottom-4 duration-1000">
      <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
        <SummaryCard label="Activos Totales" value={stats.total} colorClass="bg-cyan-500/10 text-cyan-400 border border-cyan-500/20" icon={<svg className="w-7 h-7" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M13 10V3L4 14h7v7l9-11h-7z"></path></svg>} />
        <SummaryCard label="Sistemas Operativos" value={stats.online} colorClass="bg-emerald-500/10 text-emerald-400 border border-emerald-500/20" icon={<svg className="w-7 h-7" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z"></path></svg>} />
        <SummaryCard label="Nodos Desconectados" value={stats.offline} colorClass="bg-slate-800/50 text-slate-500 border border-slate-700/50" icon={<svg className="w-7 h-7" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M18.364 18.364A9 9 0 005.636 5.636m12.728 12.728L5.636 5.636"></path></svg>} />
      </div>

      <div className="bg-slate-900/30 backdrop-blur-sm rounded-[3rem] border border-slate-800/50 p-10 shadow-2xl overflow-hidden relative group/panel">
        <div className="absolute top-0 right-0 p-8 opacity-5">
          <svg className="w-48 h-48 text-cyan-500" fill="currentColor" viewBox="0 0 24 24"><path d="M13 10V3L4 14h7v7l9-11h-7z"></path></svg>
        </div>

        <div className="flex items-center justify-between mb-10 relative z-10">
          <div>
            <h3 className="text-white font-black text-xs uppercase tracking-[0.3em] mb-2 flex items-center gap-3">
              Flujo de Datos en Tiempo Real
              <span className="flex h-2 w-2">
                <span className="animate-ping absolute inline-flex h-2 w-2 rounded-full bg-cyan-400 opacity-75"></span>
                <span className="relative inline-flex rounded-full h-2 w-2 bg-cyan-500"></span>
              </span>
            </h3>
            <p className="text-slate-500 text-[10px] font-bold uppercase tracking-widest">Monitoreo de telemetría de activos críticos</p>
          </div>
          <button className="px-4 py-2 bg-slate-800/50 hover:bg-slate-800 text-slate-400 hover:text-white rounded-xl text-[10px] font-black uppercase tracking-widest transition-all border border-slate-700/50">Ver Registro Completo</button>
        </div>

        <div className="grid grid-cols-1 gap-4 relative z-10">
          {devices.map((d, index) => {
            const isAlarm = d.value < (d.thresholds?.min ?? 20) || d.value > (d.thresholds?.max ?? 80);
            return (
              <div
                key={d.id}
                onClick={() => onSelectDevice(d)}
                style={{ animationDelay: `${index * 100}ms` }}
                className={`flex items-center justify-between p-6 rounded-[1.5rem] border transition-all duration-300 cursor-pointer group/row animate-in fade-in slide-in-from-right-4 
                  ${isAlarm
                    ? 'bg-rose-500/5 border-rose-500/20 hover:border-rose-500/40 hover:bg-rose-500/10'
                    : 'bg-slate-900/40 border-slate-800/50 hover:border-cyan-500/30 hover:bg-slate-800/60 shadow-lg'}`}
              >
                <div className="flex items-center gap-6">
                  <div className={`w-12 h-12 rounded-2xl flex items-center justify-center transition-all duration-300 group-hover/row:scale-110
                    ${isAlarm ? 'bg-rose-500/20 text-rose-500 shadow-[0_0_15px_rgba(244,63,94,0.2)]' : 'bg-slate-800 text-cyan-400 group-hover/row:bg-cyan-500/10 shadow-inner'}`}>
                    <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M9 3v2m6-2v2M9 19v2m6-2v2M5 9H3m2 6H3m18-6h-2m2 6h-2M7 19h10a2 2 0 002-2V7a2 2 0 00-2-2H7a2 2 0 00-2 2v10a2 2 0 002 2z"></path>
                    </svg>
                  </div>
                  <div>
                    <p className="text-white text-[13px] font-black uppercase tracking-wider group-hover/row:text-cyan-400 transition-colors mb-0.5">{d.name}</p>
                    <div className="flex items-center gap-2">
                      <p className="text-slate-500 text-[9px] uppercase font-bold tracking-widest leading-none">{d.mac_address}</p>
                      <span className="w-1 h-1 rounded-full bg-slate-700"></span>
                      <span className={`text-[8px] font-black uppercase tracking-tighter ${d.status === 'online' ? 'text-emerald-500/70' : 'text-slate-600'}`}>{d.status}</span>
                    </div>
                  </div>
                </div>

                <div className="flex items-center gap-10">
                  <div className="hidden lg:block w-32 h-1.5 bg-slate-800 rounded-full overflow-hidden">
                    <div
                      className={`h-full transition-all duration-1000 ${isAlarm ? 'bg-rose-500 shadow-[0_0_8px_rgba(244,63,94,0.5)]' : 'bg-cyan-500 shadow-[0_0_8px_rgba(6,182,212,0.5)]'}`}
                      style={{ width: `${Math.min(100, Math.max(5, (d.value / 100) * 100))}%` }}
                    />
                  </div>

                  <div className="text-right">
                    <div className="flex items-baseline justify-end gap-1.5 leading-none">
                      <p className={`font-black tracking-tighter text-3xl tabular-nums transition-all duration-300 ${isAlarm ? 'text-rose-500 drop-shadow-[0_0_12px_rgba(244,63,94,0.4)]' : 'text-white group-hover/row:text-cyan-400'}`}>
                        {d.value.toFixed(2)}
                      </p>
                      <span className="text-slate-500 text-[9px] font-black uppercase opacity-60 tracking-widest">{d.unit}</span>
                    </div>
                  </div>

                  <div className="p-2 rounded-xl bg-slate-800/50 text-slate-500 group-hover/row:text-cyan-400 group-hover/row:bg-cyan-500/10 transition-all duration-300">
                    <svg className="w-5 h-5 translate-x-0 group-hover/row:translate-x-1 transition-transform" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2.5" d="M9 5l7 7-7 7"></path></svg>
                  </div>
                </div>
              </div>
            );
          })}
          {devices.length === 0 && (
            <div className="flex flex-col items-center justify-center py-24 opacity-20">
              <svg className="w-16 h-16 mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="1" d="M9.172 16.172a4 4 0 015.656 0M9 10h.01M15 10h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path></svg>
              <p className="text-slate-400 text-[10px] font-black uppercase tracking-[0.4em] italic">Red vacía: esperando telemetría</p>
            </div>
          )}
        </div>
      </div>
    </div>
  );
};

export default Dashboard;
