import React from 'react';
import { Area, AreaChart, ResponsiveContainer, YAxis } from 'recharts';

interface SparklineProps {
    data: { value: number }[];
    color?: string;
}

const Sparkline: React.FC<SparklineProps> = ({ data, color = "#22d3ee" }) => {
    if (!data || data.length === 0) return null;

    return (
        <div className="w-full h-12 opacity-50 overflow-hidden">
            <ResponsiveContainer width="100%" height="100%">
                <AreaChart data={data}>
                    <defs>
                        <linearGradient id={`colorSpark-${color.replace('#', '')}`} x1="0" y1="0" x2="0" y2="1">
                            <stop offset="5%" stopColor={color} stopOpacity={0.3} />
                            <stop offset="95%" stopColor={color} stopOpacity={0} />
                        </linearGradient>
                    </defs>
                    <YAxis hide domain={['auto', 'auto']} />
                    <Area
                        type="monotone"
                        dataKey="value"
                        stroke={color}
                        strokeWidth={1.5}
                        fillOpacity={1}
                        fill={`url(#colorSpark-${color.replace('#', '')})`}
                        animationDuration={1500}
                        isAnimationActive={false} // Performance boost for dashboard lists
                    />
                </AreaChart>
            </ResponsiveContainer>
        </div>
    );
};

export default Sparkline;
