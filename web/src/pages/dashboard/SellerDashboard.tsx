import React, { useEffect, useState } from 'react';
import { supabase } from '../../lib/supabase';
import { Button } from '../../components/ui/Button';
import { Plus, Search, MapPin, CheckCircle, Clock } from 'lucide-react';

export const SellerDashboard: React.FC = () => {
  const [orders, setOrders] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);

  const fetchOrders = async () => {
    const { data, error } = await supabase
      .from('laundry_orders')
      .select(`
        id, order_reference, status, weight_kg, total_amount, payment_status, created_at,
        profiles!customer_id(full_name),
        services(name)
      `)
      .order('created_at', { ascending: false })
      .limit(20);
      
    if (!error && data) setOrders(data);
    setLoading(false);
  };

  useEffect(() => {
    fetchOrders();
    // Real-time listener for new orders/updates
    const channel = supabase.channel('schema-db-changes')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'laundry_orders' }, () => {
        fetchOrders();
      })
      .subscribe();
    return () => { supabase.removeChannel(channel); };
  }, []);

  const updateStatus = async (id: string, newStatus: string) => {
    await supabase.from('laundry_orders').update({ status: newStatus }).eq('id', id);
    // UI will auto-update via realtime listener
  };

  const getStatusColor = (status: string) => {
    const colors: any = {
      'Pending': 'bg-yellow-100 text-yellow-800',
      'Received': 'bg-blue-100 text-blue-800',
      'In Progress': 'bg-brand-100 text-brand-800',
      'Ready for Pick-up': 'bg-green-100 text-green-800',
      'Completed': 'bg-slate-100 text-slate-800'
    };
    return colors[status] || 'bg-slate-100 text-slate-800';
  };

  return (
    <div className="max-w-7xl mx-auto space-y-6">
      <div className="flex justify-between items-center">
        <div>
          <h1 className="text-3xl font-extrabold text-slate-900">Seller Dashboard</h1>
          <p className="text-slate-500 font-semibold mt-1">Manage active laundry operations.</p>
        </div>
        <Button variant="primary" className="gap-2"><Plus className="w-5 h-5"/> New Walk-in Order</Button>
      </div>

      {/* Orders Table */}
      <div className="bg-white rounded-3xl shadow-sm border border-slate-100 overflow-hidden">
        <div className="p-6 border-b border-slate-100 flex justify-between items-center">
          <h2 className="text-xl font-bold text-slate-900">Recent Orders</h2>
          <div className="relative">
            <Search className="w-5 h-5 absolute left-3 top-1/2 transform -translate-y-1/2 text-slate-400" />
            <input type="text" placeholder="Search reference..." className="pl-10 pr-4 py-2 border border-slate-200 rounded-xl focus:ring-brand-500 focus:border-brand-500 bg-slate-50 text-sm" />
          </div>
        </div>
        
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="bg-slate-50 text-slate-500 text-sm font-bold uppercase tracking-wider">
                <th className="p-4 pl-6">Order Ref</th>
                <th className="p-4">Customer</th>
                <th className="p-4">Service</th>
                <th className="p-4">Status</th>
                <th className="p-4">Payment</th>
                <th className="p-4 pr-6">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100 text-sm font-semibold text-slate-700">
              {loading ? (
                <tr><td colSpan={6} className="p-8 text-center text-slate-400">Loading orders...</td></tr>
              ) : orders.map((order) => (
                <tr key={order.id} className="hover:bg-slate-50 transition">
                  <td className="p-4 pl-6 font-bold text-brand-600">{order.order_reference}</td>
                  <td className="p-4">{order.profiles?.full_name || 'Walk-in'}</td>
                  <td className="p-4">{order.services?.name} <span className="text-slate-400">({order.weight_kg}kg)</span></td>
                  <td className="p-4">
                    <span className={`px-3 py-1 rounded-full text-xs font-bold ${getStatusColor(order.status)}`}>
                      {order.status}
                    </span>
                  </td>
                  <td className="p-4">{order.payment_status}</td>
                  <td className="p-4 pr-6">
                    {order.status === 'Pending' && <Button variant="outline" onClick={() => updateStatus(order.id, 'Received')} className="py-1 px-3 text-xs">Receive</Button>}
                    {order.status === 'Received' && <Button variant="primary" onClick={() => updateStatus(order.id, 'In Progress')} className="py-1 px-3 text-xs gap-1"><MapPin className="w-3 h-3"/> Assign RFID</Button>}
                    {order.status === 'In Progress' && <Button variant="secondary" onClick={() => updateStatus(order.id, 'Ready for Pick-up')} className="py-1 px-3 text-xs gap-1"><Clock className="w-3 h-3"/> Mark Ready</Button>}
                    {order.status === 'Ready for Pick-up' && <Button variant="primary" onClick={() => updateStatus(order.id, 'Completed')} className="py-1 px-3 text-xs gap-1"><CheckCircle className="w-3 h-3"/> Complete</Button>}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
};