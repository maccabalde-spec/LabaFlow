import React from 'react';
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { AuthProvider } from './contexts/AuthContext';
import { ProtectedRoute } from './components/auth/ProtectedRoute';
import { DashboardLayout } from './components/layout/DashboardLayout';

import { LandingPage } from './pages/LandingPage';
import { LoginPage } from './pages/auth/LoginPage';
import { AdminDashboard } from './pages/dashboard/AdminDashboard';
import { SellerDashboard } from './pages/dashboard/SellerDashboard';

const CustomerHome = () => <div className="p-8 text-center"><h1 className="text-2xl font-bold">Please open the LabaFlow Mobile App.</h1><p>Web portal for customers coming soon.</p></div>;

function App() {
  return (
    <AuthProvider>
      <BrowserRouter>
        <Routes>
          {/* Public Routes */}
          <Route path="/" element={<LandingPage />} />
          <Route path="/login" element={<LoginPage />} />

          {/* Admin Protected Routes */}
          <Route path="/admin" element={
            <ProtectedRoute allowedRoles={['admin']}>
              <DashboardLayout />
            </ProtectedRoute>
          }>
            <Route index element={<AdminDashboard />} />
            <Route path="orders" element={<SellerDashboard />} /> {/* Admins can see seller view */}
            <Route path="*" element={<Navigate to="/admin" replace />} />
          </Route>

          {/* Seller Protected Routes */}
          <Route path="/seller" element={
            <ProtectedRoute allowedRoles={['seller']}>
              <DashboardLayout />
            </ProtectedRoute>
          }>
            <Route index element={<SellerDashboard />} />
            <Route path="*" element={<Navigate to="/seller" replace />} />
          </Route>

          {/* Customer Protected Route (Fallback) */}
          <Route path="/customer" element={
            <ProtectedRoute allowedRoles={['customer']}>
              <CustomerHome />
            </ProtectedRoute>
          } />

          <Route path="*" element={<Navigate to="/" replace />} />
        </Routes>
      </BrowserRouter>
    </AuthProvider>
  );
}

export default App;