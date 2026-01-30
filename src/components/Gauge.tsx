import React from 'react';

interface GaugeProps {
    value: number;
    min: number;
    max: number;
    unit: string;
    size?: number;
    strokeWidth?: number;
}

const Gauge: React.FC<GaugeProps> = ({
    value,
    min,
    max,
    unit,
    size = 200,
    strokeWidth = 15
}) => {
    const radius = (size - strokeWidth) / 2;
    const circumference = radius * 2 * Math.PI;
    const normalizedValue = Math.min(Math.max(value, min), max);
    const percentage = ((normalizedValue - min) / (max - min)) * 100;

    // Arch calculation (we only show 270 degrees)
    const angleRange = 270;
    const offsetAngle = (360 - angleRange) / 2;
    const strokeDashoffset = circumference - (percentage / 100) * (circumference * (angleRange / 360));
    const dashArray = `${circumference * (angleRange / 360)} ${circumference}`;

    const getColor = () => {
        if (percentage < 20 || percentage > 80) return '#f43f5e'; // Rose 500
        if (percentage < 40 || percentage > 60) return '#f59e0b'; // Amber 500
        return '#22d3ee'; // Cyan 400
    };

    const color = getColor();

    return (
        <div className="relative flex items-center justify-center group" style={{ width: size, height: size }}>
            <svg
                width={size}
                height={size}
                className="transform -rotate-[225deg]"
            >
                {/* Background Track */}
                <circle
                    cx={size / 2}
                    cy={size / 2}
                    r={radius}
                    fill="transparent"
                    stroke="#1e293b" // slate-800
                    strokeWidth={strokeWidth}
                    strokeDasharray={dashArray}
                    strokeLinecap="round"
                />

                {/* Active Progress */}
                <circle
                    cx={size / 2}
                    cy={size / 2}
                    r={radius}
                    fill="transparent"
                    stroke={color}
                    strokeWidth={strokeWidth}
                    strokeDasharray={dashArray}
                    strokeDashoffset={strokeDashoffset}
                    strokeLinecap="round"
                    className="transition-all duration-1000 ease-out"
                    style={{ filter: `drop-shadow(0 0 8px ${color}44)` }}
                />
            </svg>

            <div className="absolute inset-0 flex flex-col items-center justify-center text-center">
                <span className="text-[10px] font-black uppercase text-slate-500 tracking-[0.2em] mb-1">Actual</span>
                <div className="flex items-baseline gap-1">
                    <span className="text-4xl font-black text-white brand-logo transition-all duration-500" style={{ color: color }}>
                        {value.toFixed(1)}
                    </span>
                    <span className="text-[10px] font-black text-slate-400 uppercase">{unit}</span>
                </div>
                <div className="mt-2 flex gap-4 text-[8px] font-black text-slate-600 uppercase tracking-widest">
                    <span>{min}</span>
                    <span>{max}</span>
                </div>
            </div>
        </div>
    );
};

export default Gauge;
