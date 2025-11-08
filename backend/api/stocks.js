const axios = require('axios');

const stocks = [
  'RELIANCE.NS', 'TCS.NS', 'HDFCBANK.NS', 'INFY.NS', 'ICICIBANK.NS',
  'HINDUNILVR.NS', 'ITC.NS', 'SBIN.NS', 'BHARTIARTL.NS', 'KOTAKBANK.NS',
  'LT.NS', 'AXISBANK.NS', 'ASIANPAINT.NS', 'MARUTI.NS', 'SUNPHARMA.NS',
  'TITAN.NS', 'ULTRACEMCO.NS', 'BAJFINANCE.NS', 'NESTLEIND.NS', 'WIPRO.NS',
  'HCLTECH.NS', 'TECHM.NS', 'POWERGRID.NS', 'NTPC.NS', 'ONGC.NS',
  'M&M.NS', 'TATAMOTORS.NS', 'TATASTEEL.NS', 'JSWSTEEL.NS', 'HINDALCO.NS',
  'COALINDIA.NS', 'GRASIM.NS', 'ADANIPORTS.NS', 'BAJAJFINSV.NS', 'INDUSINDBK.NS',
  'DRREDDY.NS', 'DIVISLAB.NS', 'CIPLA.NS', 'EICHERMOT.NS', 'SHREECEM.NS',
  'UPL.NS', 'APOLLOHOSP.NS', 'BRITANNIA.NS', 'HEROMOTOCO.NS', 'BAJAJ-AUTO.NS',
  'SBILIFE.NS', 'BPCL.NS', 'IOC.NS', 'ADANIENT.NS', 'TATACONSUM.NS',
  'YESBANK.NS', 'BANKBARODA.NS', 'PNB.NS', 'UNIONBANK.NS', 'CANBK.NS',
  'SUZLON.NS', 'SAIL.NS', 'NMDC.NS', 'JINDALSTEL.NS', 'VEDL.NS',
  'GAIL.NS', 'PETRONET.NS', 'HINDPETRO.NS', 'FEDERALBNK.NS', 'RBLBANK.NS',
  'LUPIN.NS', 'AUROPHARMA.NS', 'BIOCON.NS', 'CADILAHC.NS', 'TORNTPHARM.NS',
  'APOLLOTYRE.NS', 'MRF.NS', 'CEAT.NS', 'ESCORTS.NS', 'MOTHERSON.NS',
  'GODREJCP.NS', 'MARICO.NS', 'DABUR.NS', 'TATAPOWER.NS', 'ADANIGREEN.NS',
  'ACC.NS', 'AMBUJACEM.NS', 'IDEA.NS', 'BANDHANBNK.NS', 'IDFCFIRSTB.NS',
  'DLF.NS', 'GODREJPROP.NS', 'OBEROIRLTY.NS', 'LTTS.NS', 'MPHASIS.NS',
  'PERSISTENT.NS', 'COFORGE.NS', 'JUBLFOOD.NS', 'TATACOMM.NS', 'DIXON.NS',
  'VOLTAS.NS', 'HAVELLS.NS', 'CROMPTON.NS', 'BATAINDIA.NS', 'PEL.NS',
];

let cache = null;
let lastFetch = 0;
const CACHE_TIME = 5 * 60 * 1000; // 5 minutes

module.exports = async (req, res) => {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET');
  res.setHeader('Content-Type', 'application/json');
  
  try {
    const now = Date.now();
    
    if (cache && (now - lastFetch) < CACHE_TIME) {
      console.log('✅ Returning cached data');
      return res.json(cache);
    }
    
    console.log('🔄 Fetching fresh data...');
    
    const response = await axios.get(
      `https://query1.finance.yahoo.com/v7/finance/quote?symbols=${stocks.join(',')}`,
      {
        headers: { 'User-Agent': 'Mozilla/5.0' },
        timeout: 30000
      }
    );
    
    const results = response.data.quoteResponse.result;
    const allStocks = [];
    
    for (const q of results) {
      const price = q.regularMarketPrice || 0;
      const prev = q.regularMarketPreviousClose || 0;
      if (!price || !prev) continue;
      
      const change = price - prev;
      const changePct = (change / prev) * 100;
      
      allStocks.push({
        symbol: q.symbol.replace('.NS', ''),
        name: q.shortName || q.longName || q.symbol,
        price,
        change,
        changePercent: changePct,
        volume: formatVol(q.regularMarketVolume || 0),
        volumeNum: q.regularMarketVolume || 0,
        signal: getSignal(changePct)
      });
    }
    
    cache = {
      gainers: allStocks.filter(s => s.changePercent > 0)
        .sort((a, b) => b.changePercent - a.changePercent).slice(0, 15),
      losers: allStocks.filter(s => s.changePercent < 0)
        .sort((a, b) => a.changePercent - b.changePercent).slice(0, 15),
      buzzers: allStocks.sort((a, b) => b.volumeNum - a.volumeNum).slice(0, 15),
      lastUpdated: new Date().toISOString()
    };
    
    lastFetch = now;
    console.log(`✅ Success: ${allStocks.length} stocks`);
    res.json(cache);
    
  } catch (err) {
    console.error('❌ Error:', err.message);
    res.status(500).json({ error: err.message });
  }
};

function getSignal(pct) {
  return pct > 2 ? 'Buy' : pct < -2 ? 'Sell' : 'Hold';
}

function formatVol(v) {
  if (v >= 1e7) return `${(v / 1e7).toFixed(1)}Cr`;
  if (v >= 1e5) return `${(v / 1e5).toFixed(1)}L`;
  if (v >= 1e3) return `${(v / 1e3).toFixed(1)}K`;
  return v.toString();
        }
