import React from 'react';
import { Outlet, Link, useLocation } from 'react-router-dom';
import { useAuth } from '../../contexts/AuthContext';
import { LayoutDashboard, ShoppingBag, Package, Users, Settings, LogOut, Droplets } from 'lucide-react';

export const DashboardLayout: React.FC = () => {
  const { role, signOut, user } = useAuth();
  const location = useLocation();

  const navItems = [
    { name: 'Dashboard', path: `/${role}`, icon: LayoutDashboard },
    { name: 'Orders', path: `/${role}/orders`, icon: ShoppingBag },
    ...(role === 'admin' ? [
      { name: 'Inventory', path: `/admin/inventory`, icon: Package },
      { name: 'Staff & Users', path: `/admin/users`, icon: Users },
      { name: 'Settings', path: `/admin/settings`, icon: Settings },
    ] : []),
  ];

  return (
    <div className="flex h-screen bg-brand-50 overflow-hidden">
      {/* Sidebar */}
      <aside className="w-64 bg-white border-r border-slate-200 flex flex-col hidden md:flex">
        <div className="p-6 flex items-center gap-2">
          <Droplets className="w-8 h-8 text-brand-500" />
          <span className="text-2xl font-extrabold text-brand-900 tracking-tight">LabaFlow</span>
        </div>
        <div className="px-6 pb-4">
          <span className="text-xs font-bold text-slate-400 uppercase tracking-wider">{role} Panel</span>
        </div>
        <nav className="flex-1 px-4 space-y-1 overflow-y-auto">
          {navItems.map((item) => {
            const isActive = location.pathname === item.path;
            return (
              <Link key={item.name} to={item.path}
                className={`flex items-center gap-3 px-4 py-3 rounded-xl font-semibold transition-colors ${
                  isActive ? 'bg-brand-500 text-white shadow-md shadow-brand-500/20' : 'text-slate-600 hover:bg-brand-50 hover:text-brand-600'
                }`}>
                <item.icon className="w-5 h-5" /> {item.name}
              </Link>
            );
          })}
        </nav>
        <div className="p-4 border-t border-slate-200">
          <div className="px-4 py-2 mb-2 text-sm text-slate-600 font-semibold truncate">
            {user?.email}
          </div>
          <button onClick={signOut} className="flex items-center gap-3 w-full px-4 py-3 text-slate-600 hover:bg-red-50 hover:text-red-600 rounded-xl font-semibold transition">
            <LogOut className="w-5 h-5" /> Sign Out
          </button>
        </div>
      </aside>

      {/* Main Content */}
      <main className="flex-1 flex flex-col overflow-hidden">
        {/* Mobile Header goes here if needed */}
        <div className="flex-1 overflow-y-auto p-6 md:p-10">
          <Outlet />
        </div>
      </main>
    </div>
  );
};