import { NextResponse } from 'next/server';
import { createClient } from '@supabase/supabase-js';

// Supabase Client Initialize (Service Role Key for server-side admin access)
const supabase = createClient(
  process.env.SUPABASE_URL!,
  process.env.SUPABASE_SERVICE_ROLE_KEY!
);

export async function POST(request: Request) {
  try {
    const body = await request.json();
    const { trades, signals } = body;

    // 1. Master Trades ko Supabase mein save/update karein
    if (trades && Array.isArray(trades) && trades.length > 0) {
      const { error: tradesError } = await supabase
        .from('master_trades')
        .upsert(trades, { onConflict: 'ticket' }); // 'ticket' unique hai

      if (tradesError) {
        console.error('Trades insert error:', tradesError);
        return NextResponse.json({ error: 'Failed to save trades' }, { status: 500 });
      }
    }

    // 2. Master Signals ko Supabase mein save/update karein
    if (signals && Array.isArray(signals) && signals.length > 0) {
      const { error: signalsError } = await supabase
        .from('master_signals')
        .upsert(signals); 

      if (signalsError) {
        console.error('Signals insert error:', signalsError);
        return NextResponse.json({ error: 'Failed to save signals' }, { status: 500 });
      }
    }

    return NextResponse.json({ success: true, message: 'Data synced successfully' });

  } catch (error) {
    console.error('Sync API error:', error);
    return NextResponse.json({ error: 'Invalid request' }, { status: 400 });
  }
}