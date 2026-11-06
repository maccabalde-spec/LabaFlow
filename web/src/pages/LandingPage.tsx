import React from 'react';
import { Link } from 'react-router-dom';
import { Button } from '../components/ui/Button';
import { Droplets, MapPin, Wind, CheckCircle, Smartphone } from 'lucide-react';

export const LandingPage: React.FC = () => {
  return (
    <div className="min-h-screen bg-white overflow-hidden">
      {/* Navbar */}
      <nav className="max-w-7xl mx-auto px-6 py-6 flex justify-between items-center bg-transparent relative z-10">
        <div className="flex items-center gap-2">
          <Droplets className="w-8 h-8 text-brand-500" />
          <span className="text-2xl font-extrabold text-brand-900 tracking-tight">LabaFlow</span>
        </div>
        <div className="hidden md:flex gap-8 font-semibold text-slate-600">
          <a href="#how-it-works" className="hover:text-brand-500 transition">How it works</a>
          <a href="#services" className="hover:text-brand-500 transition">Services</a>
        </div>
        <div className="flex gap-4">
          <Link to="/login"><Button variant="ghost">Sign In</Button></Link>
          <Link to="/register"><Button variant="primary">Get Started</Button></Link>
        </div>
      </nav>

      {/* Hero Section */}
      <section className="relative max-w-7xl mx-auto px-6 py-12 md:py-24 grid md:grid-cols-2 gap-12 items-center">
        {/* Floating background bubbles (decorative) */}
        <div className="absolute top-20 right-20 w-64 h-64 bg-brand-100 rounded-full mix-blend-multiply filter blur-3xl opacity-70 animate-blob"></div>
        <div className="absolute top-40 right-10 w-72 h-72 bg-blue-100 rounded-full mix-blend-multiply filter blur-3xl opacity-70 animate-blob animation-delay-2000"></div>

        <div className="z-10">
          <span className="inline-block py-1 px-3 rounded-full bg-brand-100 text-brand-600 text-sm font-bold mb-6">
            Smart Laundry System
          </span>
          <h1 className="text-5xl md:text-7xl font-extrabold text-slate-900 leading-tight mb-6">
            Fresh laundry,<br />Zero hassle.
          </h1>
          <p className="text-lg md:text-xl text-slate-600 mb-8 max-w-lg">
            Lab-a-Day’s new integrated platform. Book online, track your laundry with RFID precision, and get real-time notifications when it's ready.
          </p>
          <div className="flex gap-4">
            <Link to="/register"><Button variant="primary">Book a Service</Button></Link>
            <a href="#how-it-works"><Button variant="secondary">How it works</Button></a>
          </div>
          
          <div className="mt-12 flex gap-8">
            <div>
              <p className="text-3xl font-extrabold text-slate-900">10k+</p>
              <p className="text-sm text-slate-500 font-semibold">Orders Processed</p>
            </div>
            <div>
              <p className="text-3xl font-extrabold text-slate-900">100%</p>
              <p className="text-sm text-slate-500 font-semibold">RFID Tracked</p>
            </div>
          </div>
        </div>

        {/* Hero Image Area */}
        <div className="relative z-10 flex justify-center">
          <div className="w-full max-w-md aspect-square bg-gradient-to-br from-brand-100 to-brand-50 rounded-[3rem] p-8 shadow-soft relative">
            <div className="absolute inset-0 bg-white/40 backdrop-blur-sm rounded-[3rem] border border-white/60"></div>
            {/* Mockup of Mobile App framing */}
            <div className="relative h-full w-full bg-white rounded-3xl shadow-xl overflow-hidden border-4 border-slate-900 flex flex-col items-center justify-center p-6 text-center">
               <Smartphone className="w-16 h-16 text-brand-400 mb-4" />
               <h3 className="text-xl font-bold mb-2">Track Your Order</h3>
               <div className="w-full bg-brand-50 p-4 rounded-xl mb-4">
                 <p className="text-xs text-brand-600 font-bold mb-1">STATUS</p>
                 <p className="text-lg font-bold text-slate-900">Washing & Drying</p>
               </div>
               <div className="w-3/4 h-2 bg-slate-100 rounded-full overflow-hidden">
                 <div className="w-1/2 h-full bg-brand-500 rounded-full"></div>
               </div>
            </div>
          </div>
        </div>
      </section>

      {/* How It Works */}
      <section id="how-it-works" className="bg-brand-50 py-24 px-6">
        <div className="max-w-7xl mx-auto text-center">
          <h2 className="text-sm font-bold text-brand-500 tracking-widest uppercase mb-2">Process</h2>
          <h3 className="text-4xl font-extrabold mb-16">Get it done in 4 steps</h3>
          
          <div className="grid md:grid-cols-4 gap-8">
            {[
              { step: 1, title: 'Book', desc: 'Pre-book via the LabaFlow app or walk in.', icon: Smartphone },
              { step: 2, title: 'Drop-off', desc: 'Weigh in and get a unique RFID tag assigned.', icon: MapPin },
              { step: 3, title: 'Process', desc: 'We wash, dry, and fold while you track live.', icon: Wind },
              { step: 4, title: 'Collect', desc: 'Get notified instantly when ready for pickup.', icon: CheckCircle },
            ].map((item) => (
              <div key={item.step} className="bg-white p-8 rounded-3xl shadow-soft text-center transform transition hover:-translate-y-2">
                <div className="w-16 h-16 bg-brand-100 text-brand-500 rounded-2xl flex items-center justify-center mx-auto mb-6">
                  <item.icon className="w-8 h-8" />
                </div>
                <p className="text-xs font-bold text-brand-400 mb-2">STEP {item.step}</p>
                <h4 className="text-xl font-bold mb-3">{item.title}</h4>
                <p className="text-slate-500 text-sm">{item.desc}</p>
              </div>
            ))}
          </div>
        </div>
      </section>
    </div>
  );
};