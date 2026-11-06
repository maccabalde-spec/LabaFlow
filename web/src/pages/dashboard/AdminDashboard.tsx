import React, { useEffect, useState } from 'react';
import { supabase } from '../../lib/supabase';
import { TrendingUp, Package, AlertTriangle, Users } from 'lucide-react';

export const AdminDashboard: React.FC = () => {
  const [stats, setStats] = useState({ orders: 0, revenue: 0, customers: 0 });
  const [inventory, setInventory] = useState<any[]>([]);

  useEffect(() => {
    const fetchDashboardData = async () => {
      // Fetch aggregate stats (Simple approach for demonstration)
      const { data: orders } = await supabase.from('laundry_orders').select('total_amount');
      const { count: customers } = await supabase.from('profiles').select('*', { count: 'exact', head: true }).eq('role', 'customer');
      const { data: inv } = await supabase.from('inventory_items').select('*');

      if (orders) {
        const rev = orders.reduce((sum, order) => sum + (Number(order.total_amount) || 0), 0);
        setStats({ orders: orders.length, revenue: rev, customers: customers || 0 });
      }
      if (inv) setInventory(inv);
    };

    fetchDashboardData();
  }, []);

  return (
    <div className="max-w-7xl mx-auto space-y-8">
      <div>
        <h1 className="text-3xl font-extrabold text-slate-900">Admin Overview</h1>
        <p className="text-slate-500 font-semibold mt-1">Business performance and alerts.</p>
      </div>

      {/* KPI Cards */}
      <div className="grid md:grid-cols-3 gap-6">
        <div className="bg-white p-6 rounded-3xl shadow-sm border border-slate-100 flex items-center gap-4">
          <div className="w-14 h-14 rounded-2xl bg-brand-100 text-brand-500 flex items-center justify-center"><TrendingUp className="w-7 h-7" /></div>
          <div>
            <p className="text-sm font-bold text-slate-400 uppercase">Total Revenue</p>
            <p className="text-2xl font-extrabold text-slate-900">₱{stats.revenue.toFixed(2)}</p>
          </div>
        </div>
        <div className="bg-white p-6 rounded-3xl shadow-sm border border-slate-100 flex items-center gap-4">
          <div className="w-14 h-14 rounded-2xl bg-blue-100 text-blue-500 flex items-center justify-center"><Package className="w-7 h-7" /></div>
          <div>
            <p className="text-sm font-bold text-slate-400 uppercase">Orders Processed</p>
            <p className="text-2xl font-extrabold text-slate-900">{stats.orders}</p>
          </div>
        </div>
        <div className="bg-white p-6 rounded-3xl shadow-sm border border-slate-100 flex items-center gap-4">
          <div className="w-14 h-14 rounded-2xl bg-purple-100 text-purple-500 flex items-center justify-center"><Users className="w-7 h-7" /></div>
          <div>
            <p className="text-sm font-bold text-slate-400 uppercase">Total Customers</p>
            <p className="text-2xl font-extrabold text-slate-900">{stats.customers}</p>
          </div>
        </div>
      </div>

      {/* Inventory Alerts */}
      <div className="bg-white rounded-3xl shadow-sm border border-slate-100 p-6">
        <h2 className="text-xl font-bold text-slate-900 mb-4 flex items-center gap-2"><AlertTriangle className="w-5 h-5 text-yellow-500"/> Inventory Alerts</h2>
        <div className="space-y-4">
          {inventory.map((item) => {
            const isLow = item.current_stock <= item.min_threshold;
            return (
              <div key={item.id} className={`flex justify-between items-center p-4 rounded-xl border ${isLow ? 'border-red-200 bg-red-50' : 'border-slate-100 bg-slate-50'}`}>
                <div>
                  <p className="font-bold text-slate-900">{item.name}</p>
                  <p className="text-sm font-semibold text-slate-500">Threshold: {item.min_threshold} {item.unit}</p>
                </div>
                <div className="text-right">
                  <p className={`text-xl font-extrabold ${isLow ? 'text-red-600' : 'text-slate-900'}`}>
                    {item.current_stock} <span className="text-sm">{item.unit}</span>
                  </p>
                  {isLow && <span className="text-xs font-bold text-red-500 uppercase tracking-wider">Low Stock</span>}
                </div>
              </div>
            );
          })}
        </div>
      </div>
    </div>
  );
};