import { NextResponse } from 'next/server';
import { createClient } from '@supabase/supabase-js';

// ✅ IMPORTANT: Is route ko dynamic banaya hai taake ye Next.js build time par run na ho
export const dynamic = 'force-dynamic';
export const runtime = 'nodejs';

// Supabase Client Initialize (Service Role Key for server-side admin access)
const supabaseUrl = process.env.SUPABASE_URL || process.env.NEXT_PUBLIC_SUPABASE_URL;
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

if (!supabaseUrl || !supabaseKey) {
  console.warn('⚠️ Supabase environment variables are missing. Sync will fail at runtime.');
}

const supabase = supabaseUrl && supabaseKey 
  ? createClient(supabaseUrl, supabaseKey) 
  : null;

export async function POST(request: Request) {
  try {
    // Safety check: Agar Supabase configure nahi hai to error return karein
    if (!supabase) {
      return NextResponse.json(
        { error: 'Server configuration error: Supabase credentials missing' },
        { status: 500 }
      );
    }

    const body = await request.json();
    const { trades, signals } = body;

    // 1. Master Trades ko Supabase mein save/update karein
    if (trades && Array.isArray(trades) && trades.length > 0) {
      const { error: tradesError } = await supabase
        .from('master_trades')
        .upsert(trades, { onConflict: 'ticket' });

      if (tradesError) {
        console.error('❌ Trades insert error:', tradesError);
        return NextResponse.json({ 
          error: 'Failed to save trades', 
          details: tradesError.message 
        }, { status: 500 });
      }
    }

    // 2. Master Signals ko Supabase mein save/update karein
    if (signals && Array.isArray(signals) && signals.length > 0) {
      const { error: signalsError } = await supabase
        .from('master_signals')
        .upsert(signals, { onConflict: 'ticket' });

      if (signalsError) {
        console.error('❌ Signals insert error:', signalsError);
        return NextResponse.json({ 
          error: 'Failed to save signals', 
          details: signalsError.message 
        }, { status: 500 });
      }
    }

    console.log('✅ Data synced successfully:', {
      tradesCount: trades?.length || 0,
      signalsCount: signals?.length || 0
    });

    return NextResponse.json({ 
      success: true, 
      message: 'Data synced successfully',
      counts: {
        trades: trades?.length || 0,
        signals: signals?.length || 0
      }
    }, { status: 200 });

  } catch (error) {
    // ✅ FIX: 'any' ki jagah 'unknown' use kiya - ESLint compliant
    const errorMessage = error instanceof Error 
      ? error.message 
      : 'Unknown error';
    
    console.error('❌ Sync API error:', errorMessage);
    return NextResponse.json({ 
      error: 'Invalid request', 
      details: errorMessage
    }, { status: 400 });
  }
}