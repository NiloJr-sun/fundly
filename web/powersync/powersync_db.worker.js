(function dartProgram(){function copyProperties(a,b){var s=Object.keys(a)
for(var r=0;r<s.length;r++){var q=s[r]
b[q]=a[q]}}function mixinPropertiesHard(a,b){var s=Object.keys(a)
for(var r=0;r<s.length;r++){var q=s[r]
if(!b.hasOwnProperty(q)){b[q]=a[q]}}}function mixinPropertiesEasy(a,b){Object.assign(b,a)}var z=function(){var s=function(){}
s.prototype={p:{}}
var r=new s()
if(!(Object.getPrototypeOf(r)&&Object.getPrototypeOf(r).p===s.prototype.p))return false
try{if(typeof navigator!="undefined"&&typeof navigator.userAgent=="string"&&navigator.userAgent.indexOf("Chrome/")>=0)return true
if(typeof version=="function"&&version.length==0){var q=version()
if(/^\d+\.\d+\.\d+\.\d+$/.test(q))return true}}catch(p){}return false}()
function inherit(a,b){a.prototype.constructor=a
a.prototype["$i"+a.name]=a
if(b!=null){if(z){Object.setPrototypeOf(a.prototype,b.prototype)
return}var s=Object.create(b.prototype)
copyProperties(a.prototype,s)
a.prototype=s}}function inheritMany(a,b){for(var s=0;s<b.length;s++){inherit(b[s],a)}}function mixinEasy(a,b){mixinPropertiesEasy(b.prototype,a.prototype)
a.prototype.constructor=a}function mixinHard(a,b){mixinPropertiesHard(b.prototype,a.prototype)
a.prototype.constructor=a}function lazy(a,b,c,d){var s=a
a[b]=s
a[c]=function(){if(a[b]===s){a[b]=d()}a[c]=function(){return this[b]}
return a[b]}}function lazyFinal(a,b,c,d){var s=a
a[b]=s
a[c]=function(){if(a[b]===s){var r=d()
if(a[b]!==s){A.Ev(b)}a[b]=r}var q=a[b]
a[c]=function(){return q}
return q}}function makeConstList(a,b){if(b!=null)A.u(a,b)
a.$flags=7
return a}function convertToFastObject(a){function t(){}t.prototype=a
new t()
return a}function convertAllToFastObject(a){for(var s=0;s<a.length;++s){convertToFastObject(a[s])}}var y=0
function instanceTearOffGetter(a,b){var s=null
return a?function(c){if(s===null)s=A.vZ(b)
return new s(c,this)}:function(){if(s===null)s=A.vZ(b)
return new s(this,null)}}function staticTearOffGetter(a){var s=null
return function(){if(s===null)s=A.vZ(a).prototype
return s}}var x=0
function tearOffParameters(a,b,c,d,e,f,g,h,i,j){if(typeof h=="number"){h+=x}return{co:a,iS:b,iI:c,rC:d,dV:e,cs:f,fs:g,fT:h,aI:i||0,nDA:j}}function installStaticTearOff(a,b,c,d,e,f,g,h){var s=tearOffParameters(a,true,false,c,d,e,f,g,h,false)
var r=staticTearOffGetter(s)
a[b]=r}function installInstanceTearOff(a,b,c,d,e,f,g,h,i,j){c=!!c
var s=tearOffParameters(a,false,c,d,e,f,g,h,i,!!j)
var r=instanceTearOffGetter(c,s)
a[b]=r}function setOrUpdateInterceptorsByTag(a){var s=v.interceptorsByTag
if(!s){v.interceptorsByTag=a
return}copyProperties(a,s)}function setOrUpdateLeafTags(a){var s=v.leafTags
if(!s){v.leafTags=a
return}copyProperties(a,s)}function updateTypes(a){var s=v.types
var r=s.length
s.push.apply(s,a)
return r}function updateHolder(a,b){copyProperties(b,a)
return a}var hunkHelpers=function(){var s=function(a,b,c,d,e){return function(f,g,h,i){return installInstanceTearOff(f,g,a,b,c,d,[h],i,e,false)}},r=function(a,b,c,d){return function(e,f,g,h){return installStaticTearOff(e,f,a,b,c,[g],h,d)}}
return{inherit:inherit,inheritMany:inheritMany,mixin:mixinEasy,mixinHard:mixinHard,installStaticTearOff:installStaticTearOff,installInstanceTearOff:installInstanceTearOff,_instance_0u:s(0,0,null,["$0"],0),_instance_1u:s(0,1,null,["$1"],0),_instance_2u:s(0,2,null,["$2"],0),_instance_0i:s(1,0,null,["$0"],0),_instance_1i:s(1,1,null,["$1"],0),_instance_2i:s(1,2,null,["$2"],0),_static_0:r(0,null,["$0"],0),_static_1:r(1,null,["$1"],0),_static_2:r(2,null,["$2"],0),makeConstList:makeConstList,lazy:lazy,lazyFinal:lazyFinal,updateHolder:updateHolder,convertToFastObject:convertToFastObject,updateTypes:updateTypes,setOrUpdateInterceptorsByTag:setOrUpdateInterceptorsByTag,setOrUpdateLeafTags:setOrUpdateLeafTags}}()
function initializeDeferredHunk(a){x=v.types.length
a(hunkHelpers,v,w,$)}var J={
w7(a,b,c,d){return{i:a,p:b,e:c,x:d}},
ut(a){var s,r,q,p,o,n="_$dart_js",m=a[v.dispatchPropertyName]
if(m==null)if($.w5==null){A.E1()
m=a[v.dispatchPropertyName]}if(m!=null){s=m.p
if(!1===s)return m.i
if(!0===s)return a
r=Object.getPrototypeOf(a)
if(s===r)return m.i
if(m.e===r)throw A.c(A.vs("Return interceptor for "+A.q(s(a,m))))}q=a.constructor
if(q==null)p=null
else{o=$.t_
if(o==null)o=$.t_=A.us(n)
p=q[o]}if(p!=null)return p
p=A.Eb(a)
if(p!=null)return p
if(typeof a=="function")return B.bj
s=Object.getPrototypeOf(a)
if(s==null)return B.ag
if(s===Object.prototype)return B.ag
if(typeof q=="function"){o=$.t_
if(o==null)o=$.t_=A.us(n)
Object.defineProperty(q,o,{value:B.a_,enumerable:false,writable:true,configurable:true})
return B.a_}return B.a_},
vc(a,b){if(a<0||a>4294967295)throw A.c(A.ab(a,0,4294967295,"length",null))
return J.Ap(new Array(a),b)},
vd(a,b){if(a<0)throw A.c(A.H("Length must be a non-negative integer: "+a,null))
return A.u(new Array(a),b.h("w<0>"))},
Ap(a,b){var s=A.u(a,b.h("w<0>"))
s.$flags=1
return s},
Aq(a,b){return J.wg(a,b)},
dF(a){if(typeof a=="number"){if(Math.floor(a)==a)return J.fn.prototype
return J.iy.prototype}if(typeof a=="string")return J.co.prototype
if(a==null)return J.dV.prototype
if(typeof a=="boolean")return J.ix.prototype
if(Array.isArray(a))return J.w.prototype
if(typeof a!="object"){if(typeof a=="function")return J.b_.prototype
if(typeof a=="symbol")return J.d_.prototype
if(typeof a=="bigint")return J.aN.prototype
return a}if(a instanceof A.k)return a
return J.ut(a)},
aa(a){if(typeof a=="string")return J.co.prototype
if(a==null)return a
if(Array.isArray(a))return J.w.prototype
if(typeof a!="object"){if(typeof a=="function")return J.b_.prototype
if(typeof a=="symbol")return J.d_.prototype
if(typeof a=="bigint")return J.aN.prototype
return a}if(a instanceof A.k)return a
return J.ut(a)},
bk(a){if(a==null)return a
if(Array.isArray(a))return J.w.prototype
if(typeof a!="object"){if(typeof a=="function")return J.b_.prototype
if(typeof a=="symbol")return J.d_.prototype
if(typeof a=="bigint")return J.aN.prototype
return a}if(a instanceof A.k)return a
return J.ut(a)},
DW(a){if(typeof a=="number")return J.dW.prototype
if(typeof a=="string")return J.co.prototype
if(a==null)return a
if(!(a instanceof A.k))return J.dg.prototype
return a},
w3(a){if(typeof a=="string")return J.co.prototype
if(a==null)return a
if(!(a instanceof A.k))return J.dg.prototype
return a},
ur(a){if(a==null)return a
if(typeof a!="object"){if(typeof a=="function")return J.b_.prototype
if(typeof a=="symbol")return J.d_.prototype
if(typeof a=="bigint")return J.aN.prototype
return a}if(a instanceof A.k)return a
return J.ut(a)},
A(a,b){if(a==null)return b==null
if(typeof a!="object")return b!=null&&a===b
return J.dF(a).D(a,b)},
eX(a,b){if(typeof b==="number")if(Array.isArray(a)||typeof a=="string"||A.yI(a,a[v.dispatchPropertyName]))if(b>>>0===b&&b<a.length)return a[b]
return J.aa(a).i(a,b)},
kW(a,b,c){if(typeof b==="number")if((Array.isArray(a)||A.yI(a,a[v.dispatchPropertyName]))&&!(a.$flags&2)&&b>>>0===b&&b<a.length)return a[b]=c
return J.bk(a).m(a,b,c)},
hN(a,b){return J.bk(a).q(a,b)},
zz(a,b){return J.bk(a).a7(a,b)},
zA(a,b){return J.w3(a).e2(a,b)},
zB(a){return J.ur(a).iF(a)},
cO(a,b,c){return J.ur(a).e3(a,b,c)},
zC(a,b){return J.bk(a).e6(a,b)},
wg(a,b){return J.DW(a).a0(a,b)},
wh(a,b){return J.aa(a).V(a,b)},
kX(a,b){return J.bk(a).W(a,b)},
zD(a){return J.ur(a).gau(a)},
U(a){return J.dF(a).gv(a)},
kY(a){return J.aa(a).gE(a)},
zE(a){return J.aa(a).gaO(a)},
a0(a){return J.bk(a).gA(a)},
aM(a){return J.aa(a).gk(a)},
zF(a){return J.ur(a).gjf(a)},
wi(a){return J.dF(a).ga4(a)},
dI(a,b,c){return J.bk(a).ba(a,b,c)},
zG(a,b,c){return J.w3(a).cA(a,b,c)},
zH(a,b){return J.aa(a).sk(a,b)},
zI(a,b,c,d,e){return J.bk(a).Y(a,b,c,d,e)},
kZ(a,b){return J.bk(a).aT(a,b)},
wj(a,b){return J.bk(a).cM(a,b)},
zJ(a,b){return J.w3(a).dE(a,b)},
wk(a,b){return J.bk(a).bN(a,b)},
zK(a){return J.bk(a).jy(a)},
bb(a){return J.dF(a).j(a)},
W:function W(){},
ix:function ix(){},
dV:function dV(){},
ag:function ag(){},
cp:function cp(){},
iW:function iW(){},
dg:function dg(){},
b_:function b_(){},
aN:function aN(){},
d_:function d_(){},
w:function w(a){this.$ti=a},
iw:function iw(){},
nF:function nF(a){this.$ti=a},
dJ:function dJ(a,b,c){var _=this
_.a=a
_.b=b
_.c=0
_.d=null
_.$ti=c},
dW:function dW(){},
fn:function fn(){},
iy:function iy(){},
co:function co(){}},A={vg:function vg(){},
B7(a){var s,r=a.a
if(!B.a.K(r,"_"))return r
s=B.a.c7(r,"@")
if(s===-1)return r
return B.a.t(r,0,s)},
i4(a,b,c){if(t.O.b(a))return new A.h8(a,b.h("@<0>").I(c).h("h8<1,2>"))
return new A.cR(a,b.h("@<0>").I(c).h("cR<1,2>"))},
wL(a){return new A.d1("Field '"+a+"' has been assigned during initialization.")},
wM(a){return new A.d1("Field '"+a+"' has not been initialized.")},
Au(a){return new A.d1("Field '"+a+"' has already been initialized.")},
uw(a){var s,r=a^48
if(r<=9)return r
s=a|32
if(97<=s&&s<=102)return s-87
return-1},
au(a,b){a=a+b&536870911
a=a+((a&524287)<<10)&536870911
return a^a>>>6},
fO(a){a=a+((a&67108863)<<3)&536870911
a^=a>>>11
return a+((a&16383)<<15)&536870911},
xg(a,b,c){return A.fO(A.au(A.au(c,a),b))},
bA(a,b,c){return a},
w6(a){var s,r
for(s=$.dB.length,r=0;r<s;++r)if(a===$.dB[r])return!0
return!1},
bJ(a,b,c,d){A.aH(b,"start")
if(c!=null){A.aH(c,"end")
if(b>c)A.r(A.ab(b,0,c,"start",null))}return new A.dd(a,b,c,d.h("dd<0>"))},
nR(a,b,c,d){if(t.O.b(a))return new A.bU(a,b,c.h("@<0>").I(d).h("bU<1,2>"))
return new A.bY(a,b,c.h("@<0>").I(d).h("bY<1,2>"))},
xh(a,b,c){var s="takeCount"
A.hQ(b,s)
A.aH(b,s)
if(t.O.b(a))return new A.fc(a,b,c.h("fc<0>"))
return new A.df(a,b,c.h("df<0>"))},
xa(a,b,c){var s="count"
if(t.O.b(a)){A.hQ(b,s)
A.aH(b,s)
return new A.dQ(a,b,c.h("dQ<0>"))}A.hQ(b,s)
A.aH(b,s)
return new A.c0(a,b,c.h("c0<0>"))},
bW(){return new A.aW("No element")},
wH(){return new A.aW("Too few elements")},
j8(a,b,c,d){if(c-b<=32)A.B1(a,b,c,d)
else A.B0(a,b,c,d)},
B1(a,b,c,d){var s,r,q,p,o
for(s=b+1,r=J.aa(a);s<=c;++s){q=r.i(a,s)
p=s
for(;;){if(!(p>b&&d.$2(r.i(a,p-1),q)>0))break
o=p-1
r.m(a,p,r.i(a,o))
p=o}r.m(a,p,q)}},
B0(a3,a4,a5,a6){var s,r,q,p,o,n,m,l,k,j,i=B.b.R(a5-a4+1,6),h=a4+i,g=a5-i,f=B.b.R(a4+a5,2),e=f-i,d=f+i,c=J.aa(a3),b=c.i(a3,h),a=c.i(a3,e),a0=c.i(a3,f),a1=c.i(a3,d),a2=c.i(a3,g)
if(a6.$2(b,a)>0){s=a
a=b
b=s}if(a6.$2(a1,a2)>0){s=a2
a2=a1
a1=s}if(a6.$2(b,a0)>0){s=a0
a0=b
b=s}if(a6.$2(a,a0)>0){s=a0
a0=a
a=s}if(a6.$2(b,a1)>0){s=a1
a1=b
b=s}if(a6.$2(a0,a1)>0){s=a1
a1=a0
a0=s}if(a6.$2(a,a2)>0){s=a2
a2=a
a=s}if(a6.$2(a,a0)>0){s=a0
a0=a
a=s}if(a6.$2(a1,a2)>0){s=a2
a2=a1
a1=s}c.m(a3,h,b)
c.m(a3,f,a0)
c.m(a3,g,a2)
c.m(a3,e,c.i(a3,a4))
c.m(a3,d,c.i(a3,a5))
r=a4+1
q=a5-1
p=J.A(a6.$2(a,a1),0)
if(p)for(o=r;o<=q;++o){n=c.i(a3,o)
m=a6.$2(n,a)
if(m===0)continue
if(m<0){if(o!==r){c.m(a3,o,c.i(a3,r))
c.m(a3,r,n)}++r}else for(;;){m=a6.$2(c.i(a3,q),a)
if(m>0){--q
continue}else{l=q-1
if(m<0){c.m(a3,o,c.i(a3,r))
k=r+1
c.m(a3,r,c.i(a3,q))
c.m(a3,q,n)
q=l
r=k
break}else{c.m(a3,o,c.i(a3,q))
c.m(a3,q,n)
q=l
break}}}}else for(o=r;o<=q;++o){n=c.i(a3,o)
if(a6.$2(n,a)<0){if(o!==r){c.m(a3,o,c.i(a3,r))
c.m(a3,r,n)}++r}else if(a6.$2(n,a1)>0)for(;;)if(a6.$2(c.i(a3,q),a1)>0){--q
if(q<o)break
continue}else{l=q-1
if(a6.$2(c.i(a3,q),a)<0){c.m(a3,o,c.i(a3,r))
k=r+1
c.m(a3,r,c.i(a3,q))
c.m(a3,q,n)
r=k}else{c.m(a3,o,c.i(a3,q))
c.m(a3,q,n)}q=l
break}}j=r-1
c.m(a3,a4,c.i(a3,j))
c.m(a3,j,a)
j=q+1
c.m(a3,a5,c.i(a3,j))
c.m(a3,j,a1)
A.j8(a3,a4,r-2,a6)
A.j8(a3,q+2,a5,a6)
if(p)return
if(r<h&&q>g){while(J.A(a6.$2(c.i(a3,r),a),0))++r
while(J.A(a6.$2(c.i(a3,q),a1),0))--q
for(o=r;o<=q;++o){n=c.i(a3,o)
if(a6.$2(n,a)===0){if(o!==r){c.m(a3,o,c.i(a3,r))
c.m(a3,r,n)}++r}else if(a6.$2(n,a1)===0)for(;;)if(a6.$2(c.i(a3,q),a1)===0){--q
if(q<o)break
continue}else{l=q-1
if(a6.$2(c.i(a3,q),a)<0){c.m(a3,o,c.i(a3,r))
k=r+1
c.m(a3,r,c.i(a3,q))
c.m(a3,q,n)
r=k}else{c.m(a3,o,c.i(a3,q))
c.m(a3,q,n)}q=l
break}}A.j8(a3,r,q,a6)}else A.j8(a3,r,q,a6)},
cT:function cT(a,b){this.a=a
this.$ti=b},
dK:function dK(a,b,c){var _=this
_.a=a
_.b=b
_.d=_.c=null
_.$ti=c},
cC:function cC(){},
i5:function i5(a,b){this.a=a
this.$ti=b},
cR:function cR(a,b){this.a=a
this.$ti=b},
h8:function h8(a,b){this.a=a
this.$ti=b},
h2:function h2(){},
qZ:function qZ(a,b){this.a=a
this.b=b},
ae:function ae(a,b){this.a=a
this.$ti=b},
cS:function cS(a,b){this.a=a
this.$ti=b},
lC:function lC(a,b){this.a=a
this.b=b},
lB:function lB(a){this.a=a},
d1:function d1(a){this.a=a},
bn:function bn(a){this.a=a},
uN:function uN(){},
ou:function ou(){},
x:function x(){},
X:function X(){},
dd:function dd(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.$ti=d},
as:function as(a,b,c){var _=this
_.a=a
_.b=b
_.c=0
_.d=null
_.$ti=c},
bY:function bY(a,b,c){this.a=a
this.b=b
this.$ti=c},
bU:function bU(a,b,c){this.a=a
this.b=b
this.$ti=c},
cr:function cr(a,b,c){var _=this
_.a=null
_.b=a
_.c=b
_.$ti=c},
a8:function a8(a,b,c){this.a=a
this.b=b
this.$ti=c},
c7:function c7(a,b,c){this.a=a
this.b=b
this.$ti=c},
ek:function ek(a,b){this.a=a
this.b=b},
fe:function fe(a,b,c){this.a=a
this.b=b
this.$ti=c},
il:function il(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=null
_.$ti=d},
df:function df(a,b,c){this.a=a
this.b=b
this.$ti=c},
fc:function fc(a,b,c){this.a=a
this.b=b
this.$ti=c},
jo:function jo(a,b,c){this.a=a
this.b=b
this.$ti=c},
c0:function c0(a,b,c){this.a=a
this.b=b
this.$ti=c},
dQ:function dQ(a,b,c){this.a=a
this.b=b
this.$ti=c},
j7:function j7(a,b){this.a=a
this.b=b},
cY:function cY(a){this.$ti=a},
ih:function ih(){},
fX:function fX(a,b){this.a=a
this.$ti=b},
jD:function jD(a,b){this.a=a
this.$ti=b},
fB:function fB(a,b){this.a=a
this.$ti=b},
iQ:function iQ(a){this.a=a
this.b=null},
fh:function fh(){},
jt:function jt(){},
eg:function eg(){},
da:function da(a,b){this.a=a
this.$ti=b},
fM:function fM(a){this.a=a},
hF:function hF(){},
A0(){throw A.c(A.R("Cannot modify constant Set"))},
yX(a){var s=A.yW(a)
if(s!=null)return s
return"minified:"+a},
yI(a,b){var s
if(b!=null){s=b.x
if(s!=null)return s}return t.dX.b(a)},
q(a){var s
if(typeof a=="string")return a
if(typeof a=="number"){if(a!==0)return""+a}else if(!0===a)return"true"
else if(!1===a)return"false"
else if(a==null)return"null"
s=J.bb(a)
return s},
e3(a){var s,r=$.wX
if(r==null)r=$.wX=Symbol("identityHashCode")
s=a[r]
if(s==null){s=Math.random()*0x3fffffff|0
a[r]=s}return s},
vl(a,b){var s,r=/^\s*[+-]?((0x[a-f0-9]+)|(\d+)|([a-z0-9]+))\s*$/i.exec(a)
if(r==null)return null
s=r[3]
if(s!=null)return parseInt(a,10)
if(r[2]!=null)return parseInt(a,16)
return null},
iY(a){var s,r,q,p
if(a instanceof A.k)return A.b9(A.ba(a),null)
s=J.dF(a)
if(s===B.bi||s===B.bk||t.cx.b(a)){r=B.a2(a)
if(r!=="Object"&&r!=="")return r
q=a.constructor
if(typeof q=="function"){p=q.name
if(typeof p=="string"&&p!=="Object"&&p!=="")return p}}return A.b9(A.ba(a),null)},
x3(a){var s,r,q
if(a==null||typeof a=="number"||A.kJ(a))return J.bb(a)
if(typeof a=="string")return JSON.stringify(a)
if(a instanceof A.cU)return a.j(0)
if(a instanceof A.hm)return a.it(!0)
s=$.zt()
for(r=0;r<1;++r){q=s[r].oK(a)
if(q!=null)return q}return"Instance of '"+A.iY(a)+"'"},
AI(){if(!!self.location)return self.location.href
return null},
wW(a){var s,r,q,p,o=a.length
if(o<=500)return String.fromCharCode.apply(null,a)
for(s="",r=0;r<o;r=q){q=r+500
p=q<o?q:o
s+=String.fromCharCode.apply(null,a.slice(r,p))}return s},
AM(a){var s,r,q,p=A.u([],t.t)
for(s=a.length,r=0;r<a.length;a.length===s||(0,A.a6)(a),++r){q=a[r]
if(!A.hG(q))throw A.c(A.dC(q))
if(q<=65535)p.push(q)
else if(q<=1114111){p.push(55296+(B.b.Z(q-65536,10)&1023))
p.push(56320+(q&1023))}else throw A.c(A.dC(q))}return A.wW(p)},
x4(a){var s,r,q
for(s=a.length,r=0;r<s;++r){q=a[r]
if(!A.hG(q))throw A.c(A.dC(q))
if(q<0)throw A.c(A.dC(q))
if(q>65535)return A.AM(a)}return A.wW(a)},
AN(a,b,c){var s,r,q,p
if(c<=500&&b===0&&c===a.length)return String.fromCharCode.apply(null,a)
for(s=b,r="";s<c;s=q){q=s+500
p=q<c?q:c
r+=String.fromCharCode.apply(null,a.subarray(s,p))}return r},
aQ(a){var s
if(0<=a){if(a<=65535)return String.fromCharCode(a)
if(a<=1114111){s=a-65536
return String.fromCharCode((B.b.Z(s,10)|55296)>>>0,s&1023|56320)}}throw A.c(A.ab(a,0,1114111,null,null))},
d7(a){if(a.date===void 0)a.date=new Date(a.a)
return a.date},
x2(a){var s=A.d7(a).getFullYear()+0
return s},
x0(a){var s=A.d7(a).getMonth()+1
return s},
wY(a){var s=A.d7(a).getDate()+0
return s},
wZ(a){var s=A.d7(a).getHours()+0
return s},
x_(a){var s=A.d7(a).getMinutes()+0
return s},
x1(a){var s=A.d7(a).getSeconds()+0
return s},
AK(a){var s=A.d7(a).getMilliseconds()+0
return s},
AL(a){var s=A.d7(a).getDay()+0
return B.b.aS(s+6,7)+1},
AJ(a){var s=a.$thrownJsError
if(s==null)return null
return A.M(s)},
iZ(a,b){var s
if(a.$thrownJsError==null){s=new Error()
A.al(a,s)
a.$thrownJsError=s
s.stack=b.j(0)}},
kO(a,b){var s,r="index"
if(!A.hG(b))return new A.a1(!0,b,r,null)
s=J.aM(a)
if(b<0||b>=s)return A.it(b,s,a,null,r)
return A.oc(b,r)},
DP(a,b,c){if(a<0||a>c)return A.ab(a,0,c,"start",null)
if(b!=null)if(b<a||b>c)return A.ab(b,a,c,"end",null)
return new A.a1(!0,b,"end",null)},
dC(a){return new A.a1(!0,a,null,null)},
c(a){return A.al(a,new Error())},
al(a,b){var s
if(a==null)a=new A.c3()
b.dartException=a
s=A.Ew
if("defineProperty" in Object){Object.defineProperty(b,"message",{get:s})
b.name=""}else b.toString=s
return b},
Ew(){return J.bb(this.dartException)},
r(a,b){throw A.al(a,b==null?new Error():b)},
B(a,b,c){var s
if(b==null)b=0
if(c==null)c=0
s=Error()
A.r(A.CK(a,b,c),s)},
CK(a,b,c){var s,r,q,p,o,n,m,l,k
if(typeof b=="string")s=b
else{r="[]=;add;removeWhere;retainWhere;removeRange;setRange;setInt8;setInt16;setInt32;setUint8;setUint16;setUint32;setFloat32;setFloat64".split(";")
q=r.length
p=b
if(p>q){c=p/q|0
p%=q}s=r[p]}o=typeof c=="string"?c:"modify;remove from;add to".split(";")[c]
n=t.j.b(a)?"list":"ByteData"
m=a.$flags|0
l="a "
if((m&4)!==0)k="constant "
else if((m&2)!==0){k="unmodifiable "
l="an "}else k=(m&1)!==0?"fixed-length ":""
return new A.fR("'"+s+"': Cannot "+o+" "+l+k+n)},
a6(a){throw A.c(A.am(a))},
c4(a){var s,r,q,p,o,n
a=A.yO(a.replace(String({}),"$receiver$"))
s=a.match(/\\\$[a-zA-Z]+\\\$/g)
if(s==null)s=A.u([],t.s)
r=s.indexOf("\\$arguments\\$")
q=s.indexOf("\\$argumentsExpr\\$")
p=s.indexOf("\\$expr\\$")
o=s.indexOf("\\$method\\$")
n=s.indexOf("\\$receiver\\$")
return new A.px(a.replace(new RegExp("\\\\\\$arguments\\\\\\$","g"),"((?:x|[^x])*)").replace(new RegExp("\\\\\\$argumentsExpr\\\\\\$","g"),"((?:x|[^x])*)").replace(new RegExp("\\\\\\$expr\\\\\\$","g"),"((?:x|[^x])*)").replace(new RegExp("\\\\\\$method\\\\\\$","g"),"((?:x|[^x])*)").replace(new RegExp("\\\\\\$receiver\\\\\\$","g"),"((?:x|[^x])*)"),r,q,p,o,n)},
py(a){return function($expr$){var $argumentsExpr$="$arguments$"
try{$expr$.$method$($argumentsExpr$)}catch(s){return s.message}}(a)},
xl(a){return function($expr$){try{$expr$.$method$}catch(s){return s.message}}(a)},
vh(a,b){var s=b==null,r=s?null:b.method
return new A.iz(a,r,s?null:b.receiver)},
E(a){if(a==null)return new A.iS(a)
if(a instanceof A.fd)return A.cL(a,a.a)
if(typeof a!=="object")return a
if("dartException" in a)return A.cL(a,a.dartException)
return A.Dy(a)},
cL(a,b){if(t.C.b(b))if(b.$thrownJsError==null)b.$thrownJsError=a
return b},
Dy(a){var s,r,q,p,o,n,m,l,k,j,i,h,g
if(!("message" in a))return a
s=a.message
if("number" in a&&typeof a.number=="number"){r=a.number
q=r&65535
if((B.b.Z(r,16)&8191)===10)switch(q){case 438:return A.cL(a,A.vh(A.q(s)+" (Error "+q+")",null))
case 445:case 5007:A.q(s)
return A.cL(a,new A.fC())}}if(a instanceof TypeError){p=$.z3()
o=$.z4()
n=$.z5()
m=$.z6()
l=$.z9()
k=$.za()
j=$.z8()
$.z7()
i=$.zc()
h=$.zb()
g=p.bb(s)
if(g!=null)return A.cL(a,A.vh(s,g))
else{g=o.bb(s)
if(g!=null){g.method="call"
return A.cL(a,A.vh(s,g))}else if(n.bb(s)!=null||m.bb(s)!=null||l.bb(s)!=null||k.bb(s)!=null||j.bb(s)!=null||m.bb(s)!=null||i.bb(s)!=null||h.bb(s)!=null)return A.cL(a,new A.fC())}return A.cL(a,new A.js(typeof s=="string"?s:""))}if(a instanceof RangeError){if(typeof s=="string"&&s.indexOf("call stack")!==-1)return new A.fI()
s=function(b){try{return String(b)}catch(f){}return null}(a)
return A.cL(a,new A.a1(!1,null,null,typeof s=="string"?s.replace(/^RangeError:\s*/,""):s))}if(typeof InternalError=="function"&&a instanceof InternalError)if(typeof s=="string"&&s==="too much recursion")return new A.fI()
return a},
M(a){var s
if(a instanceof A.fd)return a.b
if(a==null)return new A.ht(a)
s=a.$cachedTrace
if(s!=null)return s
s=new A.ht(a)
if(typeof a==="object")a.$cachedTrace=s
return s},
kP(a){if(a==null)return J.U(a)
if(typeof a=="object")return A.e3(a)
return J.U(a)},
DU(a,b){var s,r,q,p=a.length
for(s=0;s<p;s=q){r=s+1
q=r+1
b.m(0,a[s],a[r])}return b},
CV(a,b,c,d,e,f){switch(b){case 0:return a.$0()
case 1:return a.$1(c)
case 2:return a.$2(c,d)
case 3:return a.$3(c,d,e)
case 4:return a.$4(c,d,e,f)}throw A.c(A.wz("Unsupported number of arguments for wrapped closure"))},
dD(a,b){var s
if(a==null)return null
s=a.$identity
if(!!s)return s
s=A.DJ(a,b)
a.$identity=s
return s},
DJ(a,b){var s
switch(b){case 0:s=a.$0
break
case 1:s=a.$1
break
case 2:s=a.$2
break
case 3:s=a.$3
break
case 4:s=a.$4
break
default:s=null}if(s!=null)return s.bind(a)
return function(c,d,e){return function(f,g,h,i){return e(c,d,f,g,h,i)}}(a,b,A.CV)},
zV(a2){var s,r,q,p,o,n,m,l,k,j,i=a2.co,h=a2.iS,g=a2.iI,f=a2.nDA,e=a2.aI,d=a2.fs,c=a2.cs,b=d[0],a=c[0],a0=i[b],a1=a2.fT
a1.toString
s=h?Object.create(new A.oF().constructor.prototype):Object.create(new A.eZ(null,null).constructor.prototype)
s.$initialize=s.constructor
r=h?function static_tear_off(){this.$initialize()}:function tear_off(a3,a4){this.$initialize(a3,a4)}
s.constructor=r
r.prototype=s
s.$_name=b
s.$_target=a0
q=!h
if(q)p=A.wv(b,a0,g,f)
else{s.$static_name=b
p=a0}s.$S=A.zR(a1,h,g)
s[a]=p
for(o=p,n=1;n<d.length;++n){m=d[n]
if(typeof m=="string"){l=i[m]
k=m
m=l}else k=""
j=c[n]
if(j!=null){if(q)m=A.wv(k,m,g,f)
s[j]=m}if(n===e)o=m}s.$C=o
s.$R=a2.rC
s.$D=a2.dV
return r},
zR(a,b,c){if(typeof a=="number")return a
if(typeof a=="string"){if(b)throw A.c("Cannot compute signature for static tearoff.")
return function(d,e){return function(){return e(this,d)}}(a,A.zN)}throw A.c("Error in functionType of tearoff")},
zS(a,b,c,d){var s=A.wr
switch(b?-1:a){case 0:return function(e,f){return function(){return f(this)[e]()}}(c,s)
case 1:return function(e,f){return function(g){return f(this)[e](g)}}(c,s)
case 2:return function(e,f){return function(g,h){return f(this)[e](g,h)}}(c,s)
case 3:return function(e,f){return function(g,h,i){return f(this)[e](g,h,i)}}(c,s)
case 4:return function(e,f){return function(g,h,i,j){return f(this)[e](g,h,i,j)}}(c,s)
case 5:return function(e,f){return function(g,h,i,j,k){return f(this)[e](g,h,i,j,k)}}(c,s)
default:return function(e,f){return function(){return e.apply(f(this),arguments)}}(d,s)}},
wv(a,b,c,d){if(c)return A.zU(a,b,d)
return A.zS(b.length,d,a,b)},
zT(a,b,c,d){var s=A.wr,r=A.zO
switch(b?-1:a){case 0:throw A.c(new A.j4("Intercepted function with no arguments."))
case 1:return function(e,f,g){return function(){return f(this)[e](g(this))}}(c,r,s)
case 2:return function(e,f,g){return function(h){return f(this)[e](g(this),h)}}(c,r,s)
case 3:return function(e,f,g){return function(h,i){return f(this)[e](g(this),h,i)}}(c,r,s)
case 4:return function(e,f,g){return function(h,i,j){return f(this)[e](g(this),h,i,j)}}(c,r,s)
case 5:return function(e,f,g){return function(h,i,j,k){return f(this)[e](g(this),h,i,j,k)}}(c,r,s)
case 6:return function(e,f,g){return function(h,i,j,k,l){return f(this)[e](g(this),h,i,j,k,l)}}(c,r,s)
default:return function(e,f,g){return function(){var q=[g(this)]
Array.prototype.push.apply(q,arguments)
return e.apply(f(this),q)}}(d,r,s)}},
zU(a,b,c){var s,r
if($.wp==null)$.wp=A.wo("interceptor")
if($.wq==null)$.wq=A.wo("receiver")
s=b.length
r=A.zT(s,c,a,b)
return r},
vZ(a){return A.zV(a)},
zN(a,b){return A.hA(v.typeUniverse,A.ba(a.a),b)},
wr(a){return a.a},
zO(a){return a.b},
wo(a){var s,r,q,p=new A.eZ("receiver","interceptor"),o=Object.getOwnPropertyNames(p)
o.$flags=1
s=o
for(o=s.length,r=0;r<o;++r){q=s[r]
if(p[q]===a)return q}throw A.c(A.H("Field name "+a+" not found.",null))},
us(a){return v.getIsolateTag(a)},
EA(a,b){var s=$.o
if(s===B.f)return a
return s.iK(a,b)},
yQ(){return v.G},
Fz(a,b,c){Object.defineProperty(a,b,{value:c,enumerable:false,writable:true,configurable:true})},
Eb(a){var s,r,q,p,o,n=$.yE.$1(a),m=$.uo[n]
if(m!=null){Object.defineProperty(a,v.dispatchPropertyName,{value:m,enumerable:false,writable:true,configurable:true})
return m.i}s=$.uA[n]
if(s!=null)return s
r=v.interceptorsByTag[n]
if(r==null){q=$.yx.$2(a,n)
if(q!=null){m=$.uo[q]
if(m!=null){Object.defineProperty(a,v.dispatchPropertyName,{value:m,enumerable:false,writable:true,configurable:true})
return m.i}s=$.uA[q]
if(s!=null)return s
r=v.interceptorsByTag[q]
n=q}}if(r==null)return null
s=r.prototype
p=n[0]
if(p==="!"){m=A.uF(s)
$.uo[n]=m
Object.defineProperty(a,v.dispatchPropertyName,{value:m,enumerable:false,writable:true,configurable:true})
return m.i}if(p==="~"){$.uA[n]=s
return s}if(p==="-"){o=A.uF(s)
Object.defineProperty(Object.getPrototypeOf(a),v.dispatchPropertyName,{value:o,enumerable:false,writable:true,configurable:true})
return o.i}if(p==="+")return A.yM(a,s)
if(p==="*")throw A.c(A.vs(n))
if(v.leafTags[n]===true){o=A.uF(s)
Object.defineProperty(Object.getPrototypeOf(a),v.dispatchPropertyName,{value:o,enumerable:false,writable:true,configurable:true})
return o.i}else return A.yM(a,s)},
yM(a,b){var s=Object.getPrototypeOf(a)
Object.defineProperty(s,v.dispatchPropertyName,{value:J.w7(b,s,null,null),enumerable:false,writable:true,configurable:true})
return b},
uF(a){return J.w7(a,!1,null,!!a.$ib0)},
Ed(a,b,c){var s=b.prototype
if(v.leafTags[a]===true)return A.uF(s)
else return J.w7(s,c,null,null)},
E1(){if(!0===$.w5)return
$.w5=!0
A.E2()},
E2(){var s,r,q,p,o,n,m,l
$.uo=Object.create(null)
$.uA=Object.create(null)
A.E0()
s=v.interceptorsByTag
r=Object.getOwnPropertyNames(s)
if(typeof window!="undefined"){window
q=function(){}
for(p=0;p<r.length;++p){o=r[p]
n=$.yN.$1(o)
if(n!=null){m=A.Ed(o,s[o],n)
if(m!=null){Object.defineProperty(n,v.dispatchPropertyName,{value:m,enumerable:false,writable:true,configurable:true})
q.prototype=n}}}}for(p=0;p<r.length;++p){o=r[p]
if(/^[A-Za-z_]/.test(o)){l=s[o]
s["!"+o]=l
s["~"+o]=l
s["-"+o]=l
s["+"+o]=l
s["*"+o]=l}}},
E0(){var s,r,q,p,o,n,m=B.aR()
m=A.eS(B.aS,A.eS(B.aT,A.eS(B.a3,A.eS(B.a3,A.eS(B.aU,A.eS(B.aV,A.eS(B.aW(B.a2),m)))))))
if(typeof dartNativeDispatchHooksTransformer!="undefined"){s=dartNativeDispatchHooksTransformer
if(typeof s=="function")s=[s]
if(Array.isArray(s))for(r=0;r<s.length;++r){q=s[r]
if(typeof q=="function")m=q(m)||m}}p=m.getTag
o=m.getUnknownTag
n=m.prototypeForTag
$.yE=new A.ux(p)
$.yx=new A.uy(o)
$.yN=new A.uz(n)},
eS(a,b){return a(b)||b},
C5(a,b){var s
for(s=0;s<a.length;++s)if(!J.A(a[s],b[s]))return!1
return!0},
DO(a,b){var s=b.length,r=v.rttc[""+s+";"+a]
if(r==null)return null
if(s===0)return r
if(s===r.length)return r.apply(null,b)
return r(b)},
vf(a,b,c,d,e,f){var s=b?"m":"",r=c?"":"i",q=d?"u":"",p=e?"s":"",o=function(g,h){try{return new RegExp(g,h)}catch(n){return n}}(a,s+r+q+p+f)
if(o instanceof RegExp)return o
throw A.c(A.ai("Illegal RegExp pattern ("+String(o)+")",a,null))},
Es(a,b,c){var s
if(typeof b=="string")return a.indexOf(b,c)>=0
else if(b instanceof A.fo){s=B.a.a1(a,c)
return b.b.test(s)}else return!J.zA(b,B.a.a1(a,c)).gE(0)},
DR(a){if(a.indexOf("$",0)>=0)return a.replace(/\$/g,"$$$$")
return a},
yO(a){if(/[[\]{}()*+?.\\^$|]/.test(a))return a.replace(/[[\]{}()*+?.\\^$|]/g,"\\$&")
return a},
hK(a,b,c){var s=A.Et(a,b,c)
return s},
Et(a,b,c){var s,r,q
if(b===""){if(a==="")return c
s=a.length
for(r=c,q=0;q<s;++q)r=r+a[q]+c
return r.charCodeAt(0)==0?r:r}if(a.indexOf(b,0)<0)return a
if(a.length<500||c.indexOf("$",0)>=0)return a.split(b).join(c)
return a.replace(new RegExp(A.yO(b),"g"),A.DR(c))},
D9(a){var s=a.i(0,0)
s.toString
return s},
yt(a){return a},
yR(a,b,c,d){var s,r,q,p,o,n,m
if(c==null)c=A.D6()
for(s=b.e2(0,a),s=new A.jI(s.a,s.b,s.c),r=t.lu,q=0,p="";s.l();){o=s.d
if(o==null)o=r.a(o)
n=o.b
m=n.index
p=p+A.q(A.yt(B.a.t(a,q,m)))+A.q(c.$1(o))
q=m+n[0].length}s=p+A.q(A.yt(B.a.a1(a,q)))
return s.charCodeAt(0)==0?s:s},
Eu(a,b,c,d){var s=a.indexOf(b,d)
if(s<0)return a
return A.yS(a,s,s+b.length,c)},
yS(a,b,c,d){return a.substring(0,b)+d+a.substring(c)},
hn:function hn(a){this.a=a},
N:function N(a,b){this.a=a
this.b=b},
ho:function ho(a,b){this.a=a
this.b=b},
hp:function hp(a,b){this.a=a
this.b=b},
kd:function kd(a,b){this.a=a
this.b=b},
eE:function eE(a,b){this.a=a
this.b=b},
ke:function ke(a,b){this.a=a
this.b=b},
kf:function kf(a,b){this.a=a
this.b=b},
hq:function hq(a,b,c){this.a=a
this.b=b
this.c=c},
kg:function kg(a,b,c){this.a=a
this.b=b
this.c=c},
kh:function kh(a,b,c){this.a=a
this.b=b
this.c=c},
ki:function ki(a,b,c){this.a=a
this.b=b
this.c=c},
kj:function kj(a){this.a=a},
f4:function f4(){},
lX:function lX(a,b,c){this.a=a
this.b=b
this.c=c},
bo:function bo(a,b,c){this.a=a
this.b=b
this.$ti=c},
he:function he(a,b){this.a=a
this.$ti=b},
ey:function ey(a,b,c){var _=this
_.a=a
_.b=b
_.c=0
_.d=null
_.$ti=c},
f5:function f5(){},
f6:function f6(a,b,c){this.a=a
this.b=b
this.$ti=c},
ny:function ny(){},
fm:function fm(a,b){this.a=a
this.$ti=b},
fD:function fD(){},
px:function px(a,b,c,d,e,f){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e
_.f=f},
fC:function fC(){},
iz:function iz(a,b,c){this.a=a
this.b=b
this.c=c},
js:function js(a){this.a=a},
iS:function iS(a){this.a=a},
fd:function fd(a,b){this.a=a
this.b=b},
ht:function ht(a){this.a=a
this.b=null},
cU:function cU(){},
lI:function lI(){},
lJ:function lJ(){},
pm:function pm(){},
oF:function oF(){},
eZ:function eZ(a,b){this.a=a
this.b=b},
j4:function j4(a){this.a=a},
b1:function b1(a){var _=this
_.a=0
_.f=_.e=_.d=_.c=_.b=null
_.r=0
_.$ti=a},
nG:function nG(a){this.a=a},
nJ:function nJ(a,b){var _=this
_.a=a
_.b=b
_.d=_.c=null},
b2:function b2(a,b){this.a=a
this.$ti=b},
d2:function d2(a,b,c){var _=this
_.a=a
_.b=b
_.c=c
_.d=null},
bX:function bX(a,b){this.a=a
this.$ti=b},
b3:function b3(a,b,c){var _=this
_.a=a
_.b=b
_.c=c
_.d=null},
aF:function aF(a,b){this.a=a
this.$ti=b},
iG:function iG(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=null
_.$ti=d},
fp:function fp(a){var _=this
_.a=0
_.f=_.e=_.d=_.c=_.b=null
_.r=0
_.$ti=a},
ux:function ux(a){this.a=a},
uy:function uy(a){this.a=a},
uz:function uz(a){this.a=a},
hm:function hm(){},
ka:function ka(){},
k9:function k9(){},
kb:function kb(){},
kc:function kc(){},
fo:function fo(a,b){var _=this
_.a=a
_.b=b
_.e=_.d=_.c=null},
eC:function eC(a){this.b=a},
jH:function jH(a,b,c){this.a=a
this.b=b
this.c=c},
jI:function jI(a,b,c){var _=this
_.a=a
_.b=b
_.c=c
_.d=null},
fL:function fL(a,b){this.a=a
this.c=b},
kt:function kt(a,b,c){this.a=a
this.b=b
this.c=c},
tr:function tr(a,b,c){var _=this
_.a=a
_.b=b
_.c=c
_.d=null},
Ev(a){throw A.al(A.wL(a),new Error())},
P(){throw A.al(A.wM(""),new Error())},
yT(){throw A.al(A.Au(""),new Error())},
w9(){throw A.al(A.wL(""),new Error())},
xy(){var s=new A.jR("")
return s.b=s},
r_(a){var s=new A.jR(a)
return s.b=s},
jR:function jR(a){this.a=a
this.b=null},
kG(a,b,c){},
vS(a){var s,r,q
if(t.iy.b(a))return a
s=J.aa(a)
r=A.b4(s.gk(a),null,!1,t.z)
for(q=0;q<s.gk(a);++q)r[q]=s.i(a,q)
return r},
AC(a){return new DataView(new ArrayBuffer(a))},
wS(a,b,c){var s
A.kG(a,b,c)
s=new DataView(a,b)
return s},
bq(a,b,c){A.kG(a,b,c)
c=B.b.R(a.byteLength-b,4)
return new Int32Array(a,b,c)},
AD(a){return new Int8Array(a)},
AE(a,b,c){A.kG(a,b,c)
if(c==null)c=B.b.R(a.byteLength-b,4)
return new Uint32Array(a,b,c)},
AF(a){return new Uint8Array(a)},
aU(a,b,c){A.kG(a,b,c)
return c==null?new Uint8Array(a,b):new Uint8Array(a,b,c)},
ch(a,b,c){if(a>>>0!==a||a>=c)throw A.c(A.kO(b,a))},
ya(a,b,c){var s
if(!(a>>>0!==a))if(b==null)s=a>c
else s=b>>>0!==b||a>b||b>c
else s=!0
if(s)throw A.c(A.DP(a,b,c))
if(b==null)return c
return b},
e_:function e_(){},
bE:function bE(){},
fy:function fy(){},
kA:function kA(a){this.a=a},
fx:function fx(){},
e0:function e0(){},
cs:function cs(){},
b5:function b5(){},
iJ:function iJ(){},
iK:function iK(){},
iL:function iL(){},
iM:function iM(){},
iN:function iN(){},
iO:function iO(){},
fz:function fz(){},
fA:function fA(){},
d5:function d5(){},
hh:function hh(){},
hi:function hi(){},
hj:function hj(){},
hk:function hk(){},
vn(a,b){var s=b.c
return s==null?b.c=A.hy(a,"n",[b.x]):s},
x6(a){var s=a.w
if(s===6||s===7)return A.x6(a.x)
return s===11||s===12},
AX(a){return a.as},
Ef(a,b){var s,r=b.length
for(s=0;s<r;++s)if(!a[s].b(b[s]))return!1
return!0},
ap(a){return A.tA(v.typeUniverse,a,!1)},
E4(a,b){var s,r,q,p,o
if(a==null)return null
s=b.y
r=a.Q
if(r==null)r=a.Q=new Map()
q=b.as
p=r.get(q)
if(p!=null)return p
o=A.cJ(v.typeUniverse,a.x,s,0)
r.set(q,o)
return o},
cJ(a1,a2,a3,a4){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0=a2.w
switch(a0){case 5:case 1:case 2:case 3:case 4:return a2
case 6:s=a2.x
r=A.cJ(a1,s,a3,a4)
if(r===s)return a2
return A.xO(a1,r,!0)
case 7:s=a2.x
r=A.cJ(a1,s,a3,a4)
if(r===s)return a2
return A.xN(a1,r,!0)
case 8:q=a2.y
p=A.eR(a1,q,a3,a4)
if(p===q)return a2
return A.hy(a1,a2.x,p)
case 9:o=a2.x
n=A.cJ(a1,o,a3,a4)
m=a2.y
l=A.eR(a1,m,a3,a4)
if(n===o&&l===m)return a2
return A.vG(a1,n,l)
case 10:k=a2.x
j=a2.y
i=A.eR(a1,j,a3,a4)
if(i===j)return a2
return A.xP(a1,k,i)
case 11:h=a2.x
g=A.cJ(a1,h,a3,a4)
f=a2.y
e=A.Ds(a1,f,a3,a4)
if(g===h&&e===f)return a2
return A.xM(a1,g,e)
case 12:d=a2.y
a4+=d.length
c=A.eR(a1,d,a3,a4)
o=a2.x
n=A.cJ(a1,o,a3,a4)
if(c===d&&n===o)return a2
return A.vH(a1,n,c,!0)
case 13:b=a2.x
if(b<a4)return a2
a=a3[b-a4]
if(a==null)return a2
return a
default:throw A.c(A.hV("Attempted to substitute unexpected RTI kind "+a0))}},
eR(a,b,c,d){var s,r,q,p,o=b.length,n=A.tJ(o)
for(s=!1,r=0;r<o;++r){q=b[r]
p=A.cJ(a,q,c,d)
if(p!==q)s=!0
n[r]=p}return s?n:b},
Dt(a,b,c,d){var s,r,q,p,o,n,m=b.length,l=A.tJ(m)
for(s=!1,r=0;r<m;r+=3){q=b[r]
p=b[r+1]
o=b[r+2]
n=A.cJ(a,o,c,d)
if(n!==o)s=!0
l.splice(r,3,q,p,n)}return s?l:b},
Ds(a,b,c,d){var s,r=b.a,q=A.eR(a,r,c,d),p=b.b,o=A.eR(a,p,c,d),n=b.c,m=A.Dt(a,n,c,d)
if(q===r&&o===p&&m===n)return b
s=new A.jZ()
s.a=q
s.b=o
s.c=m
return s},
u(a,b){a[v.arrayRti]=b
return a},
kN(a){var s=a.$S
if(s!=null){if(typeof s=="number")return A.DX(s)
return a.$S()}return null},
E3(a,b){var s
if(A.x6(b))if(a instanceof A.cU){s=A.kN(a)
if(s!=null)return s}return A.ba(a)},
ba(a){if(a instanceof A.k)return A.p(a)
if(Array.isArray(a))return A.a5(a)
return A.vV(J.dF(a))},
a5(a){var s=a[v.arrayRti],r=t.dG
if(s==null)return r
if(s.constructor!==r.constructor)return r
return s},
p(a){var s=a.$ti
return s!=null?s:A.vV(a)},
vV(a){var s=a.constructor,r=s.$ccache
if(r!=null)return r
return A.CT(a,s)},
CT(a,b){var s=a instanceof A.cU?Object.getPrototypeOf(Object.getPrototypeOf(a)).constructor:b,r=A.Cg(v.typeUniverse,s.name)
b.$ccache=r
return r},
DX(a){var s,r=v.types,q=r[a]
if(typeof q=="string"){s=A.tA(v.typeUniverse,q,!1)
r[a]=s
return s}return q},
uv(a){return A.bj(A.p(a))},
w4(a){var s=A.kN(a)
return A.bj(s==null?A.ba(a):s)},
vY(a){var s
if(a instanceof A.hm)return a.hV()
s=a instanceof A.cU?A.kN(a):null
if(s!=null)return s
if(t.aJ.b(a))return J.wi(a).a
if(Array.isArray(a))return A.a5(a)
return A.ba(a)},
bj(a){var s=a.r
return s==null?a.r=new A.ty(a):s},
DS(a,b){var s,r,q=b,p=q.length
if(p===0)return t.aK
s=A.hA(v.typeUniverse,A.vY(q[0]),"@<0>")
for(r=1;r<p;++r)s=A.xR(v.typeUniverse,s,A.vY(q[r]))
return A.hA(v.typeUniverse,s,a)},
bl(a){return A.bj(A.tA(v.typeUniverse,a,!1))},
CS(a){var s=this
s.b=A.Dp(s)
return s.b(a)},
Dp(a){var s,r,q,p
if(a===t.K)return A.D0
if(A.dG(a))return A.D4
s=a.w
if(s===6)return A.CQ
if(s===1)return A.yi
if(s===7)return A.CW
r=A.Do(a)
if(r!=null)return r
if(s===8){q=a.x
if(a.y.every(A.dG)){a.f="$i"+q
if(q==="t")return A.CZ
if(a===t.m)return A.CY
return A.D3}}else if(s===10){p=A.DO(a.x,a.y)
return p==null?A.yi:p}return A.CO},
Do(a){if(a.w===8){if(a===t.S)return A.hG
if(a===t.i||a===t.q)return A.D_
if(a===t.N)return A.D2
if(a===t.y)return A.kJ}return null},
CR(a){var s=this,r=A.CN
if(A.dG(s))r=A.Cu
else if(s===t.K)r=A.Ct
else if(A.eU(s)){r=A.CP
if(s===t.I)r=A.vO
else if(s===t.T)r=A.kE
else if(s===t.o9)r=A.vN
else if(s===t.jh)r=A.Cs
else if(s===t.jX)r=A.y7
else if(s===t.mU)r=A.vP}else if(s===t.S)r=A.O
else if(s===t.N)r=A.ak
else if(s===t.y)r=A.aX
else if(s===t.q)r=A.Cr
else if(s===t.i)r=A.by
else if(s===t.m)r=A.Q
s.a=r
return s.a(a)},
CO(a){var s=this
if(a==null)return A.eU(s)
return A.E9(v.typeUniverse,A.E3(a,s),s)},
CQ(a){if(a==null)return!0
return this.x.b(a)},
D3(a){var s,r=this
if(a==null)return A.eU(r)
s=r.f
if(a instanceof A.k)return!!a[s]
return!!J.dF(a)[s]},
CZ(a){var s,r=this
if(a==null)return A.eU(r)
if(typeof a!="object")return!1
if(Array.isArray(a))return!0
s=r.f
if(a instanceof A.k)return!!a[s]
return!!J.dF(a)[s]},
CY(a){var s=this
if(a==null)return!1
if(typeof a=="object"){if(a instanceof A.k)return!!a[s.f]
return!0}if(typeof a=="function")return!0
return!1},
yh(a){if(typeof a=="object"){if(a instanceof A.k)return t.m.b(a)
return!0}if(typeof a=="function")return!0
return!1},
CN(a){var s=this
if(a==null){if(A.eU(s))return a}else if(s.b(a))return a
throw A.al(A.yd(a,s),new Error())},
CP(a){var s=this
if(a==null||s.b(a))return a
throw A.al(A.yd(a,s),new Error())},
yd(a,b){return new A.hw("TypeError: "+A.xB(a,A.b9(b,null)))},
xB(a,b){return A.ij(a)+": type '"+A.b9(A.vY(a),null)+"' is not a subtype of type '"+b+"'"},
bi(a,b){return new A.hw("TypeError: "+A.xB(a,b))},
CW(a){var s=this
return s.x.b(a)||A.vn(v.typeUniverse,s).b(a)},
D0(a){return a!=null},
Ct(a){if(a!=null)return a
throw A.al(A.bi(a,"Object"),new Error())},
D4(a){return!0},
Cu(a){return a},
yi(a){return!1},
kJ(a){return!0===a||!1===a},
aX(a){if(!0===a)return!0
if(!1===a)return!1
throw A.al(A.bi(a,"bool"),new Error())},
vN(a){if(!0===a)return!0
if(!1===a)return!1
if(a==null)return a
throw A.al(A.bi(a,"bool?"),new Error())},
by(a){if(typeof a=="number")return a
throw A.al(A.bi(a,"double"),new Error())},
y7(a){if(typeof a=="number")return a
if(a==null)return a
throw A.al(A.bi(a,"double?"),new Error())},
hG(a){return typeof a=="number"&&Math.floor(a)===a},
O(a){if(typeof a=="number"&&Math.floor(a)===a)return a
throw A.al(A.bi(a,"int"),new Error())},
vO(a){if(typeof a=="number"&&Math.floor(a)===a)return a
if(a==null)return a
throw A.al(A.bi(a,"int?"),new Error())},
D_(a){return typeof a=="number"},
Cr(a){if(typeof a=="number")return a
throw A.al(A.bi(a,"num"),new Error())},
Cs(a){if(typeof a=="number")return a
if(a==null)return a
throw A.al(A.bi(a,"num?"),new Error())},
D2(a){return typeof a=="string"},
ak(a){if(typeof a=="string")return a
throw A.al(A.bi(a,"String"),new Error())},
kE(a){if(typeof a=="string")return a
if(a==null)return a
throw A.al(A.bi(a,"String?"),new Error())},
Q(a){if(A.yh(a))return a
throw A.al(A.bi(a,"JSObject"),new Error())},
vP(a){if(a==null)return a
if(A.yh(a))return a
throw A.al(A.bi(a,"JSObject?"),new Error())},
yp(a,b){var s,r,q
for(s="",r="",q=0;q<a.length;++q,r=", ")s+=r+A.b9(a[q],b)
return s},
Di(a,b){var s,r,q,p,o,n,m=a.x,l=a.y
if(""===m)return"("+A.yp(l,b)+")"
s=l.length
r=m.split(",")
q=r.length-s
for(p="(",o="",n=0;n<s;++n,o=", "){p+=o
if(q===0)p+="{"
p+=A.b9(l[n],b)
if(q>=0)p+=" "+r[q];++q}return p+"})"},
yf(a1,a2,a3){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a=", ",a0=null
if(a3!=null){s=a3.length
if(a2==null)a2=A.u([],t.s)
else a0=a2.length
r=a2.length
for(q=s;q>0;--q)a2.push("T"+(r+q))
for(p=t.X,o="<",n="",q=0;q<s;++q,n=a){o=o+n+a2[a2.length-1-q]
m=a3[q]
l=m.w
if(!(l===2||l===3||l===4||l===5||m===p))o+=" extends "+A.b9(m,a2)}o+=">"}else o=""
p=a1.x
k=a1.y
j=k.a
i=j.length
h=k.b
g=h.length
f=k.c
e=f.length
d=A.b9(p,a2)
for(c="",b="",q=0;q<i;++q,b=a)c+=b+A.b9(j[q],a2)
if(g>0){c+=b+"["
for(b="",q=0;q<g;++q,b=a)c+=b+A.b9(h[q],a2)
c+="]"}if(e>0){c+=b+"{"
for(b="",q=0;q<e;q+=3,b=a){c+=b
if(f[q+1])c+="required "
c+=A.b9(f[q+2],a2)+" "+f[q]}c+="}"}if(a0!=null){a2.toString
a2.length=a0}return o+"("+c+") => "+d},
b9(a,b){var s,r,q,p,o,n,m=a.w
if(m===5)return"erased"
if(m===2)return"dynamic"
if(m===3)return"void"
if(m===1)return"Never"
if(m===4)return"any"
if(m===6){s=a.x
r=A.b9(s,b)
q=s.w
return(q===11||q===12?"("+r+")":r)+"?"}if(m===7)return"FutureOr<"+A.b9(a.x,b)+">"
if(m===8){p=A.Dx(a.x)
o=a.y
return o.length>0?p+("<"+A.yp(o,b)+">"):p}if(m===10)return A.Di(a,b)
if(m===11)return A.yf(a,b,null)
if(m===12)return A.yf(a.x,b,a.y)
if(m===13){n=a.x
return b[b.length-1-n]}return"?"},
Dx(a){var s=A.yW(a)
if(s!=null)return s
return"minified:"+a},
Ch(a,b){var s=a.tR[b]
while(typeof s=="string")s=a.tR[s]
return s},
Cg(a,b){var s,r,q,p,o,n=a.eT,m=n[b]
if(m==null)return A.tA(a,b,!1)
else if(typeof m=="number"){s=m
r=A.hz(a,5,"#")
q=A.tJ(s)
for(p=0;p<s;++p)q[p]=r
o=A.hy(a,b,q)
n[b]=o
return o}else return m},
Cf(a,b){return A.y4(a.tR,b)},
Ce(a,b){return A.y4(a.eT,b)},
tA(a,b,c){var s,r=a.eC,q=r.get(b)
if(q!=null)return q
s=A.xQ(a,null,b,!1)
r.set(b,s)
return s},
hA(a,b,c){var s,r,q=b.z
if(q==null)q=b.z=new Map()
s=q.get(c)
if(s!=null)return s
r=A.xQ(a,b,c,!0)
q.set(c,r)
return r},
xR(a,b,c){var s,r,q,p=b.Q
if(p==null)p=b.Q=new Map()
s=c.as
r=p.get(s)
if(r!=null)return r
q=A.vG(a,b,c.w===9?c.y:[c])
p.set(s,q)
return q},
xQ(a,b,c,d){return A.C3(A.BY(a,b,c,d))},
cH(a,b){b.a=A.CR
b.b=A.CS
return b},
hz(a,b,c){var s,r,q=a.eC.get(c)
if(q!=null)return q
s=new A.br(null,null)
s.w=b
s.as=c
r=A.cH(a,s)
a.eC.set(c,r)
return r},
xO(a,b,c){var s,r=b.as+"?",q=a.eC.get(r)
if(q!=null)return q
s=A.Cc(a,b,r,c)
a.eC.set(r,s)
return s},
Cc(a,b,c,d){var s,r,q
if(d){s=b.w
r=!0
if(!A.dG(b))if(!(b===t.P||b===t.v))if(s!==6)r=s===7&&A.eU(b.x)
if(r)return b
else if(s===1)return t.P}q=new A.br(null,null)
q.w=6
q.x=b
q.as=c
return A.cH(a,q)},
xN(a,b,c){var s,r=b.as+"/",q=a.eC.get(r)
if(q!=null)return q
s=A.Ca(a,b,r,c)
a.eC.set(r,s)
return s},
Ca(a,b,c,d){var s,r
if(d){s=b.w
if(A.dG(b)||b===t.K)return b
else if(s===1)return A.hy(a,"n",[b])
else if(b===t.P||b===t.v)return t.gK}r=new A.br(null,null)
r.w=7
r.x=b
r.as=c
return A.cH(a,r)},
Cd(a,b){var s,r,q=""+b+"^",p=a.eC.get(q)
if(p!=null)return p
s=new A.br(null,null)
s.w=13
s.x=b
s.as=q
r=A.cH(a,s)
a.eC.set(q,r)
return r},
hx(a){var s,r,q,p=a.length
for(s="",r="",q=0;q<p;++q,r=",")s+=r+a[q].as
return s},
C9(a){var s,r,q,p,o,n=a.length
for(s="",r="",q=0;q<n;q+=3,r=","){p=a[q]
o=a[q+1]?"!":":"
s+=r+p+o+a[q+2].as}return s},
hy(a,b,c){var s,r,q,p=b
if(c.length>0)p+="<"+A.hx(c)+">"
s=a.eC.get(p)
if(s!=null)return s
r=new A.br(null,null)
r.w=8
r.x=b
r.y=c
if(c.length>0)r.c=c[0]
r.as=p
q=A.cH(a,r)
a.eC.set(p,q)
return q},
vG(a,b,c){var s,r,q,p,o,n
if(b.w===9){s=b.x
r=b.y.concat(c)}else{r=c
s=b}q=s.as+(";<"+A.hx(r)+">")
p=a.eC.get(q)
if(p!=null)return p
o=new A.br(null,null)
o.w=9
o.x=s
o.y=r
o.as=q
n=A.cH(a,o)
a.eC.set(q,n)
return n},
xP(a,b,c){var s,r,q="+"+(b+"("+A.hx(c)+")"),p=a.eC.get(q)
if(p!=null)return p
s=new A.br(null,null)
s.w=10
s.x=b
s.y=c
s.as=q
r=A.cH(a,s)
a.eC.set(q,r)
return r},
xM(a,b,c){var s,r,q,p,o,n=b.as,m=c.a,l=m.length,k=c.b,j=k.length,i=c.c,h=i.length,g="("+A.hx(m)
if(j>0){s=l>0?",":""
g+=s+"["+A.hx(k)+"]"}if(h>0){s=l>0?",":""
g+=s+"{"+A.C9(i)+"}"}r=n+(g+")")
q=a.eC.get(r)
if(q!=null)return q
p=new A.br(null,null)
p.w=11
p.x=b
p.y=c
p.as=r
o=A.cH(a,p)
a.eC.set(r,o)
return o},
vH(a,b,c,d){var s,r=b.as+("<"+A.hx(c)+">"),q=a.eC.get(r)
if(q!=null)return q
s=A.Cb(a,b,c,r,d)
a.eC.set(r,s)
return s},
Cb(a,b,c,d,e){var s,r,q,p,o,n,m,l
if(e){s=c.length
r=A.tJ(s)
for(q=0,p=0;p<s;++p){o=c[p]
if(o.w===1){r[p]=o;++q}}if(q>0){n=A.cJ(a,b,r,0)
m=A.eR(a,c,r,0)
return A.vH(a,n,m,c!==m)}}l=new A.br(null,null)
l.w=12
l.x=b
l.y=c
l.as=d
return A.cH(a,l)},
BY(a,b,c,d){return{u:a,e:b,r:c,s:[],p:0,n:d}},
C3(a){var s,r,q,p,o,n,m,l=a.r,k=a.s
for(s=l.length,r=0;r<s;){q=l.charCodeAt(r)
if(q>=48&&q<=57)r=A.C_(r+1,q,l,k)
else if((((q|32)>>>0)-97&65535)<26||q===95||q===36||q===124)r=A.xI(a,r,l,k,!1)
else if(q===46)r=A.xI(a,r,l,k,!0)
else{++r
switch(q){case 44:break
case 58:k.push(!1)
break
case 33:k.push(!0)
break
case 59:k.push(A.du(a.u,a.e,k.pop()))
break
case 94:k.push(A.Cd(a.u,k.pop()))
break
case 35:k.push(A.hz(a.u,5,"#"))
break
case 64:k.push(A.hz(a.u,2,"@"))
break
case 126:k.push(A.hz(a.u,3,"~"))
break
case 60:k.push(a.p)
a.p=k.length
break
case 62:A.C1(a,k)
break
case 38:A.C0(a,k)
break
case 63:p=a.u
k.push(A.xO(p,A.du(p,a.e,k.pop()),a.n))
break
case 47:p=a.u
k.push(A.xN(p,A.du(p,a.e,k.pop()),a.n))
break
case 40:k.push(-3)
k.push(a.p)
a.p=k.length
break
case 41:A.BZ(a,k)
break
case 91:k.push(a.p)
a.p=k.length
break
case 93:o=k.splice(a.p)
A.xJ(a.u,a.e,o)
a.p=k.pop()
k.push(o)
k.push(-1)
break
case 123:k.push(a.p)
a.p=k.length
break
case 125:o=k.splice(a.p)
A.C4(a.u,a.e,o)
a.p=k.pop()
k.push(o)
k.push(-2)
break
case 43:n=l.indexOf("(",r)
k.push(l.substring(r,n))
k.push(-4)
k.push(a.p)
a.p=k.length
r=n+1
break
default:throw"Bad character "+q}}}m=k.pop()
return A.du(a.u,a.e,m)},
C_(a,b,c,d){var s,r,q=b-48
for(s=c.length;a<s;++a){r=c.charCodeAt(a)
if(!(r>=48&&r<=57))break
q=q*10+(r-48)}d.push(q)
return a},
xI(a,b,c,d,e){var s,r,q,p,o,n,m=b+1
for(s=c.length;m<s;++m){r=c.charCodeAt(m)
if(r===46){if(e)break
e=!0}else{if(!((((r|32)>>>0)-97&65535)<26||r===95||r===36||r===124))q=r>=48&&r<=57
else q=!0
if(!q)break}}p=c.substring(b,m)
if(e){s=a.u
o=a.e
if(o.w===9)o=o.x
n=A.Ch(s,o.x)[p]
if(n==null)A.r('No "'+p+'" in "'+A.AX(o)+'"')
d.push(A.hA(s,o,n))}else d.push(p)
return m},
C1(a,b){var s,r=a.u,q=A.xH(a,b),p=b.pop()
if(typeof p=="string")b.push(A.hy(r,p,q))
else{s=A.du(r,a.e,p)
switch(s.w){case 11:b.push(A.vH(r,s,q,a.n))
break
default:b.push(A.vG(r,s,q))
break}}},
BZ(a,b){var s,r,q,p=a.u,o=b.pop(),n=null,m=null
if(typeof o=="number")switch(o){case-1:n=b.pop()
break
case-2:m=b.pop()
break
default:b.push(o)
break}else b.push(o)
s=A.xH(a,b)
o=b.pop()
switch(o){case-3:o=b.pop()
if(n==null)n=p.sEA
if(m==null)m=p.sEA
r=A.du(p,a.e,o)
q=new A.jZ()
q.a=s
q.b=n
q.c=m
b.push(A.xM(p,r,q))
return
case-4:b.push(A.xP(p,b.pop(),s))
return
default:throw A.c(A.hV("Unexpected state under `()`: "+A.q(o)))}},
C0(a,b){var s=b.pop()
if(0===s){b.push(A.hz(a.u,1,"0&"))
return}if(1===s){b.push(A.hz(a.u,4,"1&"))
return}throw A.c(A.hV("Unexpected extended operation "+A.q(s)))},
xH(a,b){var s=b.splice(a.p)
A.xJ(a.u,a.e,s)
a.p=b.pop()
return s},
du(a,b,c){if(typeof c=="string")return A.hy(a,c,a.sEA)
else if(typeof c=="number"){b.toString
return A.C2(a,b,c)}else return c},
xJ(a,b,c){var s,r=c.length
for(s=0;s<r;++s)c[s]=A.du(a,b,c[s])},
C4(a,b,c){var s,r=c.length
for(s=2;s<r;s+=3)c[s]=A.du(a,b,c[s])},
C2(a,b,c){var s,r,q=b.w
if(q===9){if(c===0)return b.x
s=b.y
r=s.length
if(c<=r)return s[c-1]
c-=r
b=b.x
q=b.w}else if(c===0)return b
if(q!==8)throw A.c(A.hV("Indexed base must be an interface type"))
s=b.y
if(c<=s.length)return s[c-1]
throw A.c(A.hV("Bad index "+c+" for "+b.j(0)))},
E9(a,b,c){var s,r=b.d
if(r==null)r=b.d=new Map()
s=r.get(c)
if(s==null){s=A.ax(a,b,null,c,null)
r.set(c,s)}return s},
ax(a,b,c,d,e){var s,r,q,p,o,n,m,l,k,j,i
if(b===d)return!0
if(A.dG(d))return!0
s=b.w
if(s===4)return!0
if(A.dG(b))return!1
if(b.w===1)return!0
r=s===13
if(r)if(A.ax(a,c[b.x],c,d,e))return!0
q=d.w
p=t.P
if(b===p||b===t.v){if(q===7)return A.ax(a,b,c,d.x,e)
return d===p||d===t.v||q===6}if(d===t.K){if(s===7)return A.ax(a,b.x,c,d,e)
return s!==6}if(s===7){if(!A.ax(a,b.x,c,d,e))return!1
return A.ax(a,A.vn(a,b),c,d,e)}if(s===6)return A.ax(a,p,c,d,e)&&A.ax(a,b.x,c,d,e)
if(q===7){if(A.ax(a,b,c,d.x,e))return!0
return A.ax(a,b,c,A.vn(a,d),e)}if(q===6)return A.ax(a,b,c,p,e)||A.ax(a,b,c,d.x,e)
if(r)return!1
p=s!==11
if((!p||s===12)&&d===t.gY)return!0
o=s===10
if(o&&d===t.lZ)return!0
if(q===12){if(b===t.g)return!0
if(s!==12)return!1
n=b.y
m=d.y
l=n.length
if(l!==m.length)return!1
c=c==null?n:n.concat(c)
e=e==null?m:m.concat(e)
for(k=0;k<l;++k){j=n[k]
i=m[k]
if(!A.ax(a,j,c,i,e)||!A.ax(a,i,e,j,c))return!1}return A.yg(a,b.x,c,d.x,e)}if(q===11){if(b===t.g)return!0
if(p)return!1
return A.yg(a,b,c,d,e)}if(s===8){if(q!==8)return!1
return A.CX(a,b,c,d,e)}if(o&&q===10)return A.D1(a,b,c,d,e)
return!1},
yg(a3,a4,a5,a6,a7){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1,a2
if(!A.ax(a3,a4.x,a5,a6.x,a7))return!1
s=a4.y
r=a6.y
q=s.a
p=r.a
o=q.length
n=p.length
if(o>n)return!1
m=n-o
l=s.b
k=r.b
j=l.length
i=k.length
if(o+j<n+i)return!1
for(h=0;h<o;++h){g=q[h]
if(!A.ax(a3,p[h],a7,g,a5))return!1}for(h=0;h<m;++h){g=l[h]
if(!A.ax(a3,p[o+h],a7,g,a5))return!1}for(h=0;h<i;++h){g=l[m+h]
if(!A.ax(a3,k[h],a7,g,a5))return!1}f=s.c
e=r.c
d=f.length
c=e.length
for(b=0,a=0;a<c;a+=3){a0=e[a]
for(;;){if(b>=d)return!1
a1=f[b]
b+=3
if(a0<a1)return!1
a2=f[b-2]
if(a1<a0){if(a2)return!1
continue}g=e[a+1]
if(a2&&!g)return!1
g=f[b-1]
if(!A.ax(a3,e[a+2],a7,g,a5))return!1
break}}while(b<d){if(f[b+1])return!1
b+=3}return!0},
CX(a,b,c,d,e){var s,r,q,p,o,n=b.x,m=d.x
while(n!==m){s=a.tR[n]
if(s==null)return!1
if(typeof s=="string"){n=s
continue}r=s[m]
if(r==null)return!1
q=r.length
p=q>0?new Array(q):v.typeUniverse.sEA
for(o=0;o<q;++o)p[o]=A.hA(a,b,r[o])
return A.y6(a,p,null,c,d.y,e)}return A.y6(a,b.y,null,c,d.y,e)},
y6(a,b,c,d,e,f){var s,r=b.length
for(s=0;s<r;++s)if(!A.ax(a,b[s],d,e[s],f))return!1
return!0},
D1(a,b,c,d,e){var s,r=b.y,q=d.y,p=r.length
if(p!==q.length)return!1
if(b.x!==d.x)return!1
for(s=0;s<p;++s)if(!A.ax(a,r[s],c,q[s],e))return!1
return!0},
eU(a){var s=a.w,r=!0
if(!(a===t.P||a===t.v))if(!A.dG(a))if(s!==6)r=s===7&&A.eU(a.x)
return r},
dG(a){var s=a.w
return s===2||s===3||s===4||s===5||a===t.X},
y4(a,b){var s,r,q=Object.keys(b),p=q.length
for(s=0;s<p;++s){r=q[s]
a[r]=b[r]}},
tJ(a){return a>0?new Array(a):v.typeUniverse.sEA},
br:function br(a,b){var _=this
_.a=a
_.b=b
_.r=_.f=_.d=_.c=null
_.w=0
_.as=_.Q=_.z=_.y=_.x=null},
jZ:function jZ(){this.c=this.b=this.a=null},
ty:function ty(a){this.a=a},
jV:function jV(){},
hw:function hw(a){this.a=a},
Br(){var s,r,q
if(self.scheduleImmediate!=null)return A.Dz()
if(self.MutationObserver!=null&&self.document!=null){s={}
r=self.document.createElement("div")
q=self.document.createElement("span")
s.a=null
new self.MutationObserver(A.dD(new A.qG(s),1)).observe(r,{childList:true})
return new A.qF(s,r,q)}else if(self.setImmediate!=null)return A.DA()
return A.DB()},
Bs(a){self.scheduleImmediate(A.dD(new A.qH(a),0))},
Bt(a){self.setImmediate(A.dD(new A.qI(a),0))},
Bu(a){A.xk(B.a6,a)},
xk(a,b){var s=B.b.R(a.a,1000)
return A.C8(s<0?0:s,b)},
C8(a,b){var s=new A.tw()
s.kS(a,b)
return s},
i(a){return new A.h_(new A.l($.o,a.h("l<0>")),a.h("h_<0>"))},
h(a,b){a.$2(0,null)
b.b=!0
return b.a},
b(a,b){A.y8(a,b)},
f(a,b){b.U(a)},
e(a,b){b.b8(A.E(a),A.M(a))},
y8(a,b){var s,r,q=new A.tQ(b),p=new A.tR(b)
if(a instanceof A.l)a.ir(q,p,t.z)
else{s=t.z
if(a instanceof A.l)a.bc(q,p,s)
else{r=new A.l($.o,t._)
r.a=8
r.c=a
r.ir(q,p,s)}}},
d(a){var s=function(b,c){return function(d,e){while(true){try{b(d,e)
break}catch(q){e=q
d=c}}}}(a,1),r=$.o
return r.cW(r,new A.ui(s),t.H,t.S,t.z)},
kF(a,b,c){var s,r,q
if(b===0){s=c.c
if(s!=null)s.bT(null)
else c.a.n()
return}else if(b===1){s=c.c
if(s!=null){r=A.E(a)
q=A.M(a)
s.ac(new A.a2(r,q))}else{s=c.a
s.ag(A.E(a),A.M(a))
s.n()}return}if(a instanceof A.hd){if(c.c!=null){b.$2(2,null)
return}s=a.b
if(s===0){c.a.q(0,a.a)
A.kQ(new A.tO(c,b))
return}else if(s===1){c.a.e1(a.a,!1).aK(new A.tP(c,b),t.P)
return}}A.y8(a,b)},
Dr(a){var s=a.a
return new A.a4(s,A.p(s).h("a4<1>"))},
Bv(a,b){var s=null,r=new A.jK(A.bH(s,s,s,s,!1,b),b.h("jK<0>"))
r.kN(a,b)
return r},
D7(a,b){return A.Bv(a,b)},
BQ(a){return new A.hd(a,1)},
xF(a){return new A.hd(a,0)},
xL(a,b,c){return 0},
cj(a){var s
if(t.C.b(a)){s=a.gbz()
if(s!=null)return s}return B.t},
Af(a,b){var s=new A.l($.o,b.h("l<0>"))
A.jq(B.a6,new A.n3(a,s))
return s},
dT(a,b){var s,r,q,p,o,n,m,l=null
try{l=a.$0()}catch(q){s=A.E(q)
r=A.M(q)
p=new A.l($.o,b.h("l<0>"))
o=s
n=r
m=A.dA(o,n)
if(m==null)o=new A.a2(o,n==null?A.cj(o):n)
else o=m
p.T(o)
return p}return b.h("n<0>").b(l)?l:A.bL(l,b)},
n2(a,b){var s=a==null?b.a(a):a,r=new A.l($.o,b.h("l<0>"))
r.aD(s)
return r},
n4(a,b){var s,r,q,p,o,n,m,l,k,j,i={},h=null,g=!1,f=new A.l($.o,b.h("l<t<0>>"))
i.a=null
i.b=0
i.c=i.d=null
s=new A.n6(i,h,g,f)
try{for(n=J.a0(a),m=t.P;n.l();){r=n.gp()
q=i.b
r.bc(new A.n5(i,q,f,b,h,g),s,m);++i.b}n=i.b
if(n===0){n=f
n.bT(A.u([],b.h("w<0>")))
return n}i.a=A.b4(n,null,!1,b.h("0?"))}catch(l){p=A.E(l)
o=A.M(l)
if(i.b===0||g){n=f
m=p
k=o
j=A.dA(m,k)
if(j==null)m=new A.a2(m,k==null?A.cj(m):k)
else m=j
n.T(m)
return n}else{i.d=p
i.c=o}}return f},
ir(a,b,c,d){var s=new A.mX(d,null,b,c),r=$.o,q=new A.l(r,c.h("l<0>"))
if(r!==B.f)s=r.cW(r,s,c.h("0/"),t.K,t.l)
a.cj(new A.bg(q,2,null,s,a.$ti.h("@<1>").I(c).h("bg<1,2>")))
return q},
v9(a,b){var s,r,q,p=A.u([],b.h("w<bM<0>>"))
for(s=a.length,r=b.h("bM<0>"),q=0;q<a.length;a.length===s||(0,A.a6)(a),++q)p.push(new A.bM(a[q],r))
if(p.length===0)return A.n2(A.u([],b.h("w<0>")),b.h("t<0>"))
s=new A.l($.o,b.h("l<t<0>>"))
A.xC(p,new A.mY(new A.L(s,b.h("L<t<0>>")),p,b))
return s},
Db(a){return a!=null},
Ae(a,b,c){var s=b.h("@<0>").I(c),r=new A.l($.o,s.h("l<+(1,2)>")),q=new A.bM(a.a,b.h("bM<0>")),p=new A.bM(a.b,c.h("bM<0>"))
A.xC(A.u([q,p],t.dB),new A.n1(new A.L(r,s.h("L<+(1,2)>")),q,p))
return r},
xC(a,b){var s,r={},q=r.a=r.b=0,p=new A.rw(r,a,b)
for(s=a.length;q<a.length;a.length===s||(0,A.a6)(a),++q)a[q].ms(p)},
dA(a,b){var s,r,q,p=$.o
if(p===B.f)return null
s=p.lh(p,a,b)
if(s==null)return null
r=s.a
q=s.b
if(t.C.b(r))A.iZ(r,q)
return s},
aw(a,b){var s
if($.o!==B.f){s=A.dA(a,b)
if(s!=null)return s}if(b==null)if(t.C.b(a)){b=a.gbz()
if(b==null){A.iZ(a,B.t)
b=B.t}}else b=B.t
else if(t.C.b(a))A.iZ(a,b)
return new A.a2(a,b)},
BK(a,b,c){var s=new A.l(b,c.h("l<0>"))
s.a=8
s.c=a
return s},
bL(a,b){var s=new A.l($.o,b.h("l<0>"))
s.a=8
s.c=a
return s},
rC(a,b,c){var s,r,q,p,o={},n=o.a=a
while(s=n.a,(s&4)!==0){n=n.c
o.a=n}if(n===b){s=A.ec()
b.T(new A.a2(new A.a1(!0,n,null,"Cannot complete a future with itself"),s))
return}r=b.a&1
s=n.a=s|r
if((s&24)===0){q=b.c
b.a=b.a&1|4
b.c=n
n.i7(q)
return}if(!c)if(b.c==null)n=(s&16)===0||r!==0
else n=!1
else n=!0
if(n){q=b.cX()
b.dH(o.a)
A.ds(b,q)
return}b.a^=2
p=b.b
p.bD(p,new A.rD(o,b))},
ds(a,b){var s,r,q,p,o,n,m,l,k,j,i,h,g={},f=g.a=a
for(;;){s={}
r=f.a
q=(r&16)===0
p=!q
if(b==null){if(p&&(r&1)===0){r=f.c
f=f.b
f.b1(f,r.a,r.b)}return}s.a=b
o=b.a
for(f=b;o!=null;f=o,o=n){f.a=null
A.ds(g.a,f)
s.a=o
n=o.a}r=g.a
m=r.c
s.b=p
s.c=m
if(q){l=f.c
l=(l&1)!==0||(l&15)===8}else l=!0
if(l){k=f.b.b
if(p&&r.b.ax!=k.ax){f=r.b
f.b1(f,m.a,m.b)
return}j=$.o
if(j!==k)$.o=k
else j=null
f=f.c
if((f&15)===8)new A.rH(s,g,p).$0()
else if(q){if((f&1)!==0)new A.rG(s,m).$0()}else if((f&2)!==0)new A.rF(g,s).$0()
if(j!=null)$.o=j
f=s.c
if(f instanceof A.l){r=s.a.$ti
r=r.h("n<2>").b(f)||!r.y[1].b(f)}else r=!1
if(r){i=s.a.b
if((f.a&24)!==0){h=i.c
i.c=null
b=i.dR(h)
i.a=f.a&30|i.a&1
i.c=f.c
g.a=f
continue}else A.rC(f,i,!0)
return}}i=s.a.b
h=i.c
i.c=null
b=i.dR(h)
f=s.b
r=s.c
if(!f){i.a=8
i.c=r}else{i.a=i.a&1|16
i.c=r}g.a=i
f=i}},
yn(a,b){if(t.ng.b(a))return b.cW(b,a,t.z,t.K,t.l)
if(t.mq.b(a))return b.c_(b,a,t.z,t.K)
throw A.c(A.aZ(a,"onError",u.w))},
Da(){var s,r
for(s=$.eP;s!=null;s=$.eP){$.hI=null
r=s.b
$.eP=r
if(r==null)$.hH=null
s.a.$0()}},
Dq(){$.vW=!0
try{A.Da()}finally{$.hI=null
$.vW=!1
if($.eP!=null)$.wb().$1(A.yy())}},
yr(a){var s=new A.jJ(a),r=$.hH
if(r==null){$.eP=$.hH=s
if(!$.vW)$.wb().$1(A.yy())}else $.hH=r.b=s},
Dn(a){var s,r,q,p=$.eP
if(p==null){A.yr(a)
$.hI=$.hH
return}s=new A.jJ(a)
r=$.hI
if(r==null){s.b=p
$.eP=$.hI=s}else{q=r.b
s.b=q
$.hI=r.b=s
if(q==null)$.hH=s}},
kQ(a){var s=$.o
if(B.f===s){A.vX(B.f,a)
return}if(s.y==null&&s.ax==null){A.vX(s,s.b4(s,a,t.H))
return}s.bD(s,s.e4(a))},
xb(a,b){var s=null,r=b.h("bK<0>"),q=new A.bK(s,s,s,s,r)
q.N(a)
q.hy()
return new A.a4(q,r.h("a4<1>"))},
EQ(a){return new A.bO(A.bA(a,"stream",t.K))},
bH(a,b,c,d,e,f){return e?new A.cG(b,c,d,a,f.h("cG<0>")):new A.bK(b,c,d,a,f.h("bK<0>"))},
c2(a,b){var s=null
return a?new A.dw(s,s,b.h("dw<0>")):new A.h0(s,s,b.h("h0<0>"))},
kK(a){var s,r,q,p
if(a==null)return
try{a.$0()}catch(q){s=A.E(q)
r=A.M(q)
p=$.o
p.b1(p,s,r)}},
BI(a,b,c,d,e,f){var s=$.o,r=e?1:0,q=c!=null?32:0,p=A.jN(s,b,f),o=A.jO(s,c),n=d==null?A.uj():d
return new A.cD(a,p,o,s.b4(s,n,t.H),s,r|q,f.h("cD<0>"))},
Bp(a,b,c){var s=$.o,r=a.geQ(),q=a.gdG()
return new A.fZ(new A.l(s,t._),b.B(r,!1,a.geW(),q))},
Bq(a){return new A.qD(a)},
jN(a,b,c){var s=b==null?A.DD():b
return a.c_(a,s,t.H,c)},
jO(a,b){if(b==null)b=A.DE()
if(t.r.b(b))return a.cW(a,b,t.z,t.K,t.l)
if(t.i6.b(b))return a.c_(a,b,t.z,t.K)
throw A.c(A.H(u.y,null))},
Dc(a){},
De(a,b){var s=$.o
s.b1(s,a,b)},
Dd(){},
xA(a,b){var s=$.o,r=new A.et(s,b.h("et<0>"))
A.kQ(r.gi4())
if(a!=null)r.c=s.b4(s,a,t.H)
return r},
Dl(a,b,c){var s,r,q,p
try{b.$1(a.$0())}catch(p){s=A.E(p)
r=A.M(p)
q=A.dA(s,r)
if(q!=null)c.$2(q.a,q.b)
else c.$2(s,r)}},
CC(a,b,c){var s=a.u()
if(s!==$.cM())s.J(new A.tU(b,c))
else b.ac(c)},
CD(a,b){return new A.tT(a,b)},
CE(a,b,c){var s=a.u()
if(s!==$.cM())s.J(new A.tV(b,c))
else b.bf(c)},
y5(a,b,c){var s=A.dA(b,c)
if(s!=null){b=s.a
c=s.b}a.ab(b,c)},
jq(a,b){var s=$.o
if(s===B.f)return s.hH(s,a,b)
return s.hH(s,a,s.e4(b))},
Eo(a,b,c){return A.Dm(a,null,b,c)},
Dm(a,b,c,d){var s=$.o,r=s.hQ(s,c,b)
return r.c2(r,a,d)},
Bo(){return new A.dk(B.f)},
Dk(a,b){A.Dn(new A.u5(a,b))},
vX(a,b){if(B.f!==a)b=a.ax!=null?a.e4(b):a.iJ(b,t.H)
A.yr(b)},
Dj(a,b,c){var s,r,q,p,o,n,m,l,k,j,i,h,g=null
if(c!=null){s=t.X
s=A.va(g,g,g,s,s)
s.a7(0,c)
r=new A.tN(B.f,s)}else r=g
if(b!=null){q=b.x
p=b.a
s=new A.dk(B.f)
o=q==null?g:new A.tM(B.f,q)
n=p==null?g:new A.tL(B.f,p)
m=o==null
l=m?a.y:o
k=n==null
j=k?a.ax:n
i=r==null
h=i?a.ay:r
h=s.a=new A.c8(a,s,a.c,a.d,a.e,a.f,a.r,a.w,a.x,l,a.z,a.Q,a.as,a.at,j,h)
if(!m)o.a=h
if(!k)n.a=h
if(!i)r.a=h
return h}s=new A.dk(B.f)
o=r==null
n=o?a.ay:r
n=s.a=new A.c8(a,s,a.c,a.d,a.e,a.f,a.r,a.w,a.x,a.y,a.z,a.Q,a.as,a.at,a.ax,n)
if(!o)r.a=n
return n},
qG:function qG(a){this.a=a},
qF:function qF(a,b,c){this.a=a
this.b=b
this.c=c},
qH:function qH(a){this.a=a},
qI:function qI(a){this.a=a},
tw:function tw(){this.b=null},
tx:function tx(a,b){this.a=a
this.b=b},
h_:function h_(a,b){this.a=a
this.b=!1
this.$ti=b},
tQ:function tQ(a){this.a=a},
tR:function tR(a){this.a=a},
ui:function ui(a){this.a=a},
tO:function tO(a,b){this.a=a
this.b=b},
tP:function tP(a,b){this.a=a
this.b=b},
jK:function jK(a,b){var _=this
_.a=a
_.b=!1
_.c=null
_.$ti=b},
qN:function qN(a,b){this.a=a
this.b=b},
qO:function qO(a,b){this.a=a
this.b=b},
qK:function qK(a){this.a=a},
qL:function qL(a,b){this.a=a
this.b=b},
qM:function qM(a,b,c){this.a=a
this.b=b
this.c=c},
qJ:function qJ(a){this.a=a},
hd:function hd(a,b){this.a=a
this.b=b},
kv:function kv(a){var _=this
_.a=a
_.e=_.d=_.c=_.b=null},
eI:function eI(a,b){this.a=a
this.$ti=b},
a2:function a2(a,b){this.a=a
this.b=b},
ao:function ao(a,b){this.a=a
this.$ti=b},
dm:function dm(a,b,c,d,e,f,g){var _=this
_.ay=0
_.CW=_.ch=null
_.w=a
_.a=b
_.b=c
_.c=d
_.d=e
_.e=f
_.r=_.f=null
_.$ti=g},
ca:function ca(){},
dw:function dw(a,b,c){var _=this
_.a=a
_.b=b
_.c=0
_.r=_.f=_.e=_.d=null
_.$ti=c},
tt:function tt(a,b){this.a=a
this.b=b},
tv:function tv(a,b,c){this.a=a
this.b=b
this.c=c},
tu:function tu(a){this.a=a},
h0:function h0(a,b,c){var _=this
_.a=a
_.b=b
_.c=0
_.r=_.f=_.e=_.d=null
_.$ti=c},
n3:function n3(a,b){this.a=a
this.b=b},
n6:function n6(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=d},
n5:function n5(a,b,c,d,e,f){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e
_.f=f},
mX:function mX(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=d},
jp:function jp(a,b){this.a=a
this.b=b},
mY:function mY(a,b,c){this.a=a
this.b=b
this.c=c},
n1:function n1(a,b,c){this.a=a
this.b=b
this.c=c},
e1:function e1(a,b){this.c=a
this.d=b},
bM:function bM(a,b){var _=this
_.a=a
_.c=_.b=null
_.$ti=b},
rx:function rx(a,b){this.a=a
this.b=b},
ry:function ry(a,b){this.a=a
this.b=b},
rw:function rw(a,b,c){this.a=a
this.b=b
this.c=c},
dn:function dn(){},
a9:function a9(a,b){this.a=a
this.$ti=b},
L:function L(a,b){this.a=a
this.$ti=b},
bg:function bg(a,b,c,d,e){var _=this
_.a=null
_.b=a
_.c=b
_.d=c
_.e=d
_.$ti=e},
l:function l(a,b){var _=this
_.a=0
_.b=a
_.c=null
_.$ti=b},
rz:function rz(a,b){this.a=a
this.b=b},
rE:function rE(a,b){this.a=a
this.b=b},
rD:function rD(a,b){this.a=a
this.b=b},
rB:function rB(a,b){this.a=a
this.b=b},
rA:function rA(a,b){this.a=a
this.b=b},
rH:function rH(a,b,c){this.a=a
this.b=b
this.c=c},
rI:function rI(a,b){this.a=a
this.b=b},
rJ:function rJ(a){this.a=a},
rG:function rG(a,b){this.a=a
this.b=b},
rF:function rF(a,b){this.a=a
this.b=b},
rK:function rK(a,b){this.a=a
this.b=b},
rL:function rL(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=d},
rM:function rM(a,b,c){this.a=a
this.b=b
this.c=c},
rN:function rN(a,b){this.a=a
this.b=b},
jJ:function jJ(a){this.a=a
this.b=null},
C:function C(){},
oM:function oM(a,b,c){this.a=a
this.b=b
this.c=c},
oL:function oL(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=d},
oR:function oR(a,b){this.a=a
this.b=b},
oS:function oS(a,b,c,d,e,f){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e
_.f=f},
oP:function oP(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=d},
oQ:function oQ(a,b){this.a=a
this.b=b},
oT:function oT(a,b){this.a=a
this.b=b},
oU:function oU(a,b){this.a=a
this.b=b},
oN:function oN(a){this.a=a},
oO:function oO(a,b,c){this.a=a
this.b=b
this.c=c},
fK:function fK(){},
jk:function jk(){},
cE:function cE(){},
tn:function tn(a){this.a=a},
tm:function tm(a){this.a=a},
kw:function kw(){},
jL:function jL(){},
bK:function bK(a,b,c,d,e){var _=this
_.a=null
_.b=0
_.c=null
_.d=a
_.e=b
_.f=c
_.r=d
_.$ti=e},
cG:function cG(a,b,c,d,e){var _=this
_.a=null
_.b=0
_.c=null
_.d=a
_.e=b
_.f=c
_.r=d
_.$ti=e},
a4:function a4(a,b){this.a=a
this.$ti=b},
cD:function cD(a,b,c,d,e,f,g){var _=this
_.w=a
_.a=b
_.b=c
_.c=d
_.d=e
_.e=f
_.r=_.f=null
_.$ti=g},
fZ:function fZ(a,b){this.a=a
this.b=b},
qD:function qD(a){this.a=a},
qC:function qC(a){this.a=a},
ks:function ks(a,b,c){this.c=a
this.a=b
this.b=c},
av:function av(){},
qY:function qY(a,b,c){this.a=a
this.b=b
this.c=c},
qX:function qX(a){this.a=a},
eH:function eH(){},
jU:function jU(){},
bv:function bv(a){this.b=a
this.a=null},
es:function es(a,b){this.b=a
this.c=b
this.a=null},
ro:function ro(){},
eD:function eD(){this.a=0
this.c=this.b=null},
tb:function tb(a,b){this.a=a
this.b=b},
et:function et(a,b){var _=this
_.a=1
_.b=a
_.c=null
_.$ti=b},
bO:function bO(a){this.a=null
this.b=a
this.c=!1},
dr:function dr(a){this.$ti=a},
bx:function bx(a,b,c){this.a=a
this.b=b
this.$ti=c},
t9:function t9(a,b){this.a=a
this.b=b},
hg:function hg(a,b,c,d,e){var _=this
_.a=null
_.b=0
_.c=null
_.d=a
_.e=b
_.f=c
_.r=d
_.$ti=e},
tU:function tU(a,b){this.a=a
this.b=b},
tT:function tT(a,b){this.a=a
this.b=b},
tV:function tV(a,b){this.a=a
this.b=b},
b8:function b8(){},
ex:function ex(a,b,c,d,e,f,g){var _=this
_.w=a
_.x=null
_.a=b
_.b=c
_.c=d
_.d=e
_.e=f
_.r=_.f=null
_.$ti=g},
cf:function cf(a,b,c){this.b=a
this.a=b
this.$ti=c},
aL:function aL(a,b,c){this.b=a
this.a=b
this.$ti=c},
h9:function h9(a){this.a=a},
eF:function eF(a,b,c,d,e,f){var _=this
_.w=$
_.x=null
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e
_.r=_.f=null
_.$ti=f},
c9:function c9(a,b,c){this.a=a
this.b=b
this.$ti=c},
kr:function kr(a){this.a=a},
tM:function tM(a,b){this.a=a
this.b=b},
tL:function tL(a,b){this.a=a
this.b=b},
tN:function tN(a,b){this.a=a
this.b=b},
c8:function c8(a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e
_.f=f
_.r=g
_.w=h
_.x=i
_.y=j
_.z=k
_.Q=l
_.as=m
_.at=n
_.ax=o
_.ay=p},
qs:function qs(a,b,c){this.a=a
this.b=b
this.c=c},
qr:function qr(a,b){this.a=a
this.b=b},
qt:function qt(a,b,c){this.a=a
this.b=b
this.c=c},
dk:function dk(a){this.a=a},
u5:function u5(a,b){this.a=a
this.b=b},
qq:function qq(a,b,c,d,e,f,g,h,i,j,k,l,m){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e
_.f=f
_.r=g
_.w=h
_.x=i
_.y=j
_.z=k
_.Q=l
_.as=m},
va(a,b,c,d,e){if(c==null)if(b==null){if(a==null)return new A.cc(d.h("@<0>").I(e).h("cc<1,2>"))
b=A.w0()}else{if(A.yB()===b&&A.yA()===a)return new A.dt(d.h("@<0>").I(e).h("dt<1,2>"))
if(a==null)a=A.w_()}else{if(b==null)b=A.w0()
if(a==null)a=A.w_()}return A.BJ(a,b,c,d,e)},
xD(a,b){var s=a[b]
return s===a?null:s},
vD(a,b,c){if(c==null)a[b]=a
else a[b]=c},
vC(){var s=Object.create(null)
A.vD(s,"<non-identifier-key>",s)
delete s["<non-identifier-key>"]
return s},
BJ(a,b,c,d,e){var s=c!=null?c:new A.rk(d)
return new A.h4(a,b,s,d.h("@<0>").I(e).h("h4<1,2>"))},
vi(a,b,c,d){if(b==null){if(a==null)return new A.b1(c.h("@<0>").I(d).h("b1<1,2>"))
b=A.w0()}else{if(A.yB()===b&&A.yA()===a)return new A.fp(c.h("@<0>").I(d).h("fp<1,2>"))
if(a==null)a=A.w_()}return A.BW(a,b,null,c,d)},
bD(a,b,c){return A.DU(a,new A.b1(b.h("@<0>").I(c).h("b1<1,2>")))},
T(a,b){return new A.b1(a.h("@<0>").I(b).h("b1<1,2>"))},
BW(a,b,c,d,e){return new A.hf(a,b,new A.t7(d),d.h("@<0>").I(e).h("hf<1,2>"))},
vj(a){return new A.cd(a.h("cd<0>"))},
bp(a){return new A.cd(a.h("cd<0>"))},
vF(){var s=Object.create(null)
s["<non-identifier-key>"]=s
delete s["<non-identifier-key>"]
return s},
BX(a,b,c){var s=new A.eA(a,b,c.h("eA<0>"))
s.c=a.e
return s},
CH(a,b){return J.A(a,b)},
CI(a){return J.U(a)},
An(a){var s=new A.kl(a)
if(s.l())return s.gp()
return null},
wN(a,b,c){var s=A.vi(null,null,b,c)
a.ad(0,new A.nK(s,b,c))
return s},
Av(a,b){var s,r,q=A.vj(b)
for(s=a.length,r=0;r<a.length;a.length===s||(0,A.a6)(a),++r)q.q(0,b.a(a[r]))
return q},
Aw(a,b){var s=A.vj(b)
s.a7(0,a)
return s},
Ax(a,b){var s=t.bP
return J.wg(s.a(a),s.a(b))},
nP(a){var s,r
if(A.w6(a))return"{...}"
s=new A.Z("")
try{r={}
$.dB.push(a)
s.a+="{"
r.a=!0
a.ad(0,new A.nQ(r,s))
s.a+="}"}finally{$.dB.pop()}r=s.a
return r.charCodeAt(0)==0?r:r},
nL(a){return new A.fs(A.b4(A.Ay(null),null,!1,a.h("0?")),a.h("fs<0>"))},
Ay(a){return 8},
cc:function cc(a){var _=this
_.a=0
_.e=_.d=_.c=_.b=null
_.$ti=a},
rO:function rO(a){this.a=a},
dt:function dt(a){var _=this
_.a=0
_.e=_.d=_.c=_.b=null
_.$ti=a},
h4:function h4(a,b,c,d){var _=this
_.f=a
_.r=b
_.w=c
_.a=0
_.e=_.d=_.c=_.b=null
_.$ti=d},
rk:function rk(a){this.a=a},
hb:function hb(a,b){this.a=a
this.$ti=b},
k_:function k_(a,b,c){var _=this
_.a=a
_.b=b
_.c=0
_.d=null
_.$ti=c},
hf:function hf(a,b,c,d){var _=this
_.w=a
_.x=b
_.y=c
_.a=0
_.f=_.e=_.d=_.c=_.b=null
_.r=0
_.$ti=d},
t7:function t7(a){this.a=a},
cd:function cd(a){var _=this
_.a=0
_.f=_.e=_.d=_.c=_.b=null
_.r=0
_.$ti=a},
t8:function t8(a){this.a=a
this.c=this.b=null},
eA:function eA(a,b,c){var _=this
_.a=a
_.b=b
_.d=_.c=null
_.$ti=c},
nK:function nK(a,b,c){this.a=a
this.b=b
this.c=c},
d3:function d3(a){var _=this
_.b=_.a=0
_.c=null
_.$ti=a},
k6:function k6(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=null
_.d=c
_.e=!1
_.$ti=d},
aG:function aG(){},
y:function y(){},
F:function F(){},
nO:function nO(a){this.a=a},
nQ:function nQ(a,b){this.a=a
this.b=b},
kz:function kz(){},
fu:function fu(){},
dh:function dh(a,b){this.a=a
this.$ti=b},
fs:function fs(a,b){var _=this
_.a=a
_.d=_.c=_.b=0
_.$ti=b},
k7:function k7(a,b,c,d,e){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=null
_.$ti=e},
cw:function cw(){},
hs:function hs(){},
hB:function hB(){},
yk(a,b){var s,r,q,p=null
try{p=JSON.parse(a)}catch(r){s=A.E(r)
q=A.ai(String(s),null,null)
throw A.c(q)}q=A.tW(p)
return q},
tW(a){var s
if(a==null)return null
if(typeof a!="object")return a
if(!Array.isArray(a))return new A.k3(a,Object.create(null))
for(s=0;s<a.length;++s)a[s]=A.tW(a[s])
return a},
Cq(a,b,c){var s,r,q,p,o=c-b
if(o<=4096)s=$.zi()
else s=new Uint8Array(o)
for(r=J.aa(a),q=0;q<o;++q){p=r.i(a,b+q)
if((p&255)!==p)p=255
s[q]=p}return s},
Cp(a,b,c,d){var s=a?$.zh():$.zg()
if(s==null)return null
if(0===c&&d===b.length)return A.y2(s,b)
return A.y2(s,b.subarray(c,d))},
y2(a,b){var s,r
try{s=a.decode(b)
return s}catch(r){}return null},
wl(a,b,c,d,e,f){if(B.b.aS(f,4)!==0)throw A.c(A.ai("Invalid base64 padding, padded length must be multiple of four, is "+f,a,c))
if(d+e!==f)throw A.c(A.ai("Invalid base64 padding, '=' not at the end",a,b))
if(e>2)throw A.c(A.ai("Invalid base64 padding, more than two '=' characters",a,b))},
Bw(a,b,c,d,e,f,g,h){var s,r,q,p,o,n,m,l=h>>>2,k=3-(h&3)
for(s=J.aa(b),r=f.$flags|0,q=c,p=0;q<d;++q){o=s.i(b,q)
p=(p|o)>>>0
l=(l<<8|o)&16777215;--k
if(k===0){n=g+1
r&2&&A.B(f)
f[g]=a.charCodeAt(l>>>18&63)
g=n+1
f[n]=a.charCodeAt(l>>>12&63)
n=g+1
f[g]=a.charCodeAt(l>>>6&63)
g=n+1
f[n]=a.charCodeAt(l&63)
l=0
k=3}}if(p>=0&&p<=255){if(e&&k<3){n=g+1
m=n+1
if(3-k===1){r&2&&A.B(f)
f[g]=a.charCodeAt(l>>>2&63)
f[n]=a.charCodeAt(l<<4&63)
f[m]=61
f[m+1]=61}else{r&2&&A.B(f)
f[g]=a.charCodeAt(l>>>10&63)
f[n]=a.charCodeAt(l>>>4&63)
f[m]=a.charCodeAt(l<<2&63)
f[m+1]=61}return 0}return(l<<2|3-k)>>>0}for(q=c;q<d;){o=s.i(b,q)
if(o<0||o>255)break;++q}throw A.c(A.aZ(b,"Not a byte value at index "+q+": 0x"+B.b.oI(s.i(b,q),16),null))},
wy(a){return B.bx.i(0,a.toLowerCase())},
wK(a,b,c){return new A.fq(a,b)},
CJ(a){return a.ew()},
BR(a,b){return new A.t2(a,[],A.DL())},
BS(a,b,c){var s,r=new A.Z("")
A.xG(a,r,b,c)
s=r.a
return s.charCodeAt(0)==0?s:s},
xG(a,b,c,d){var s=A.BR(b,c)
s.eB(a)},
BT(a,b,c){var s,r,q
for(s=J.aa(a),r=b,q=0;r<c;++r)q=(q|s.i(a,r))>>>0
if(q>=0&&q<=255)return
A.BU(a,b,c)},
BU(a,b,c){var s,r,q
for(s=J.aa(a),r=b;r<c;++r){q=s.i(a,r)
if(q<0||q>255)throw A.c(A.ai("Source contains non-Latin-1 characters.",a,r))}},
BV(a){return new A.ez(a,new A.dv(a))},
y3(a){switch(a){case 65:return"Missing extension byte"
case 67:return"Unexpected extension byte"
case 69:return"Invalid UTF-8 byte"
case 71:return"Overlong encoding"
case 73:return"Out of unicode range"
case 75:return"Encoded surrogate"
case 77:return"Unfinished UTF-8 octet sequence"
default:return""}},
k3:function k3(a,b){this.a=a
this.b=b
this.c=null},
k4:function k4(a){this.a=a},
t0:function t0(a,b,c){this.b=a
this.c=b
this.a=c},
tH:function tH(){},
tG:function tG(){},
hR:function hR(){},
ky:function ky(){},
hT:function hT(a){this.a=a},
tz:function tz(a,b){this.a=a
this.b=b},
kx:function kx(){},
hS:function hS(a,b){this.a=a
this.b=b},
rr:function rr(a){this.a=a},
te:function te(a){this.a=a},
ld:function ld(){},
hX:function hX(){},
qP:function qP(){},
qW:function qW(a){this.c=null
this.a=0
this.b=a},
qQ:function qQ(){},
qE:function qE(a,b){this.a=a
this.b=b},
lu:function lu(){},
jP:function jP(a){this.a=a},
jQ:function jQ(a,b){this.a=a
this.b=b
this.c=0},
i7:function i7(){},
dp:function dp(a,b){this.a=a
this.b=b},
i8:function i8(){},
af:function af(){},
m0:function m0(a){this.a=a},
cZ:function cZ(){},
mQ:function mQ(){},
mR:function mR(){},
fq:function fq(a,b){this.a=a
this.b=b},
iA:function iA(a,b){this.a=a
this.b=b},
nH:function nH(){},
iC:function iC(a){this.b=a},
t1:function t1(a,b,c){var _=this
_.a=a
_.b=b
_.c=c
_.d=!1},
iB:function iB(a){this.a=a},
t3:function t3(){},
t4:function t4(a,b){this.a=a
this.b=b},
t2:function t2(a,b,c){this.c=a
this.a=b
this.b=c},
iD:function iD(){},
iF:function iF(a){this.a=a},
iE:function iE(a,b){this.a=a
this.b=b},
k5:function k5(a){this.a=a},
t5:function t5(a){this.a=a},
nI:function nI(){},
t6:function t6(){},
ez:function ez(a,b){var _=this
_.e=a
_.a=b
_.c=_.b=null
_.d=!1},
jm:function jm(){},
ts:function ts(a,b){this.a=a
this.b=b},
hv:function hv(){},
dv:function dv(a){this.a=a},
kB:function kB(a,b,c){this.a=a
this.b=b
this.c=c},
jz:function jz(){},
jB:function jB(){},
kC:function kC(a){this.b=this.a=0
this.c=a},
tI:function tI(a,b){var _=this
_.d=a
_.b=_.a=0
_.c=b},
jA:function jA(a){this.a=a},
cI:function cI(a){this.a=a
this.b=16
this.c=0},
kD:function kD(){},
BA(a,b){var s,r,q=$.ci(),p=a.length,o=4-p%4
if(o===4)o=0
for(s=0,r=0;r<p;++r){s=s*10+a.charCodeAt(r)-48;++o
if(o===4){q=q.aL(0,$.wc()).dw(0,A.qR(s))
s=0
o=0}}if(b)return q.by(0)
return q},
xr(a){if(48<=a&&a<=57)return a-48
return(a|32)-97+10},
BB(a,b,c){var s,r,q,p,o,n,m,l=a.length,k=l-b,j=B.ab.mM(k/4),i=new Uint16Array(j),h=j-1,g=k-h*4
for(s=b,r=0,q=0;q<g;++q,s=p){p=s+1
o=A.xr(a.charCodeAt(s))
if(o>=16)return null
r=r*16+o}n=h-1
i[h]=r
for(;s<l;n=m){for(r=0,q=0;q<4;++q,s=p){p=s+1
o=A.xr(a.charCodeAt(s))
if(o>=16)return null
r=r*16+o}m=n-1
i[n]=r}if(j===1&&i[0]===0)return $.ci()
l=A.bf(j,i)
return new A.az(l===0?!1:c,i,l)},
BD(a,b){var s,r,q,p,o
if(a==="")return null
s=$.ze().j0(a)
if(s==null)return null
r=s.b
q=r[1]==="-"
p=r[4]
o=r[3]
if(p!=null)return A.BA(p,q)
if(o!=null)return A.BB(o,2,q)
return null},
bf(a,b){for(;;){if(!(a>0&&b[a-1]===0))break;--a}return a},
vA(a,b,c,d){var s,r=new Uint16Array(d),q=c-b
for(s=0;s<q;++s)r[s]=a[b+s]
return r},
qR(a){var s,r,q,p,o=a<0
if(o){if(a===-9223372036854776e3){s=new Uint16Array(4)
s[3]=32768
r=A.bf(4,s)
return new A.az(r!==0,s,r)}a=-a}if(a<65536){s=new Uint16Array(1)
s[0]=a
r=A.bf(1,s)
return new A.az(r===0?!1:o,s,r)}if(a<=4294967295){s=new Uint16Array(2)
s[0]=a&65535
s[1]=B.b.Z(a,16)
r=A.bf(2,s)
return new A.az(r===0?!1:o,s,r)}r=B.b.R(B.b.giL(a)-1,16)+1
s=new Uint16Array(r)
for(q=0;a!==0;q=p){p=q+1
s[q]=a&65535
a=B.b.R(a,65536)}r=A.bf(r,s)
return new A.az(r===0?!1:o,s,r)},
vB(a,b,c,d){var s,r,q
if(b===0)return 0
if(c===0&&d===a)return b
for(s=b-1,r=d.$flags|0;s>=0;--s){q=a[s]
r&2&&A.B(d)
d[s+c]=q}for(s=c-1;s>=0;--s){r&2&&A.B(d)
d[s]=0}return b+c},
Bz(a,b,c,d){var s,r,q,p,o,n=B.b.R(c,16),m=B.b.aS(c,16),l=16-m,k=B.b.cK(1,l)-1
for(s=b-1,r=d.$flags|0,q=0;s>=0;--s){p=a[s]
o=B.b.cL(p,l)
r&2&&A.B(d)
d[s+n+1]=(o|q)>>>0
q=B.b.cK((p&k)>>>0,m)}r&2&&A.B(d)
d[n]=q},
xs(a,b,c,d){var s,r,q,p,o=B.b.R(c,16)
if(B.b.aS(c,16)===0)return A.vB(a,b,o,d)
s=b+o+1
A.Bz(a,b,c,d)
for(r=d.$flags|0,q=o;--q,q>=0;){r&2&&A.B(d)
d[q]=0}p=s-1
return d[p]===0?p:s},
BC(a,b,c,d){var s,r,q,p,o=B.b.R(c,16),n=B.b.aS(c,16),m=16-n,l=B.b.cK(1,n)-1,k=B.b.cL(a[o],n),j=b-o-1
for(s=d.$flags|0,r=0;r<j;++r){q=a[r+o+1]
p=B.b.cK((q&l)>>>0,m)
s&2&&A.B(d)
d[r]=(p|k)>>>0
k=B.b.cL(q,n)}s&2&&A.B(d)
d[j]=k},
qS(a,b,c,d){var s,r=b-d
if(r===0)for(s=b-1;s>=0;--s){r=a[s]-c[s]
if(r!==0)return r}return r},
Bx(a,b,c,d,e){var s,r,q
for(s=e.$flags|0,r=0,q=0;q<d;++q){r+=a[q]+c[q]
s&2&&A.B(e)
e[q]=r&65535
r=B.b.Z(r,16)}for(q=d;q<b;++q){r+=a[q]
s&2&&A.B(e)
e[q]=r&65535
r=B.b.Z(r,16)}s&2&&A.B(e)
e[b]=r},
jM(a,b,c,d,e){var s,r,q
for(s=e.$flags|0,r=0,q=0;q<d;++q){r+=a[q]-c[q]
s&2&&A.B(e)
e[q]=r&65535
r=0-(B.b.Z(r,16)&1)}for(q=d;q<b;++q){r+=a[q]
s&2&&A.B(e)
e[q]=r&65535
r=0-(B.b.Z(r,16)&1)}},
xx(a,b,c,d,e,f){var s,r,q,p,o,n
if(a===0)return
for(s=d.$flags|0,r=0;--f,f>=0;e=o,c=q){q=c+1
p=a*b[c]+d[e]+r
o=e+1
s&2&&A.B(d)
d[e]=p&65535
r=B.b.R(p,65536)}for(;r!==0;e=o){n=d[e]+r
o=e+1
s&2&&A.B(d)
d[e]=n&65535
r=B.b.R(n,65536)}},
By(a,b,c){var s,r=b[c]
if(r===a)return 65535
s=B.b.kE((r<<16|b[c-1])>>>0,a)
if(s>65535)return 65535
return s},
E_(a){return A.kP(a)},
wB(a){var s=!0
s=typeof a=="string"
if(s)A.wA(a)},
wA(a){throw A.c(A.aZ(a,"object","Expandos are not allowed on strings, numbers, bools, records or null"))},
jY(a,b){var s=$.zf()
s=s==null?null:new s(A.dD(A.EA(a,b),1))
return new A.jX(s,b.h("jX<0>"))},
yG(a){var s=A.vl(a,null)
if(s!=null)return s
throw A.c(A.ai(a,null,null))},
Aa(a,b){a=A.al(a,new Error())
a.stack=b.j(0)
throw a},
b4(a,b,c,d){var s,r=c?J.vd(a,d):J.vc(a,d)
if(a!==0&&b!=null)for(s=0;s<r.length;++s)r[s]=b
return r},
AA(a,b,c){var s,r=A.u([],c.h("w<0>"))
for(s=J.a0(a);s.l();)r.push(s.gp())
r.$flags=1
return r},
an(a,b){var s,r
if(Array.isArray(a))return A.u(a.slice(0),b.h("w<0>"))
s=A.u([],b.h("w<0>"))
for(r=J.a0(a);r.l();)s.push(r.gp())
return s},
nM(a,b){var s=A.AA(a,!1,b)
s.$flags=3
return s},
bI(a,b,c){var s,r,q,p,o
A.aH(b,"start")
s=c==null
r=!s
if(r){q=c-b
if(q<0)throw A.c(A.ab(c,b,null,"end",null))
if(q===0)return""}if(Array.isArray(a)){p=a
o=p.length
if(s)c=o
return A.x4(b>0||c<o?p.slice(b,c):p)}if(t.Z.b(a))return A.B5(a,b,c)
if(r)a=J.wk(a,c)
if(b>0)a=J.kZ(a,b)
s=A.an(a,t.S)
return A.x4(s)},
B5(a,b,c){var s=a.length
if(b>=s)return""
return A.AN(a,b,c==null||c>s?s:c)},
at(a,b){return new A.fo(a,A.vf(a,!1,b,!1,!1,""))},
DZ(a,b){return a==null?b==null:a===b},
vp(a,b,c){var s=J.a0(b)
if(!s.l())return a
if(c.length===0){do a+=A.q(s.gp())
while(s.l())}else{a+=A.q(s.gp())
while(s.l())a=a+c+A.q(s.gp())}return a},
vt(){var s,r,q=A.AI()
if(q==null)throw A.c(A.R("'Uri.base' is not supported"))
s=$.xp
if(s!=null&&q===$.xo)return s
r=A.di(q)
$.xp=r
$.xo=q
return r},
ec(){return A.M(new Error())},
mN(a){var s=B.b.aS(a,1000),r=B.b.R(a-s,1000)
if(r<-864e13||r>864e13)A.r(A.ab(r,-864e13,864e13,"millisecondsSinceEpoch",null))
if(r===864e13&&s!==0)A.r(A.aZ(s,"microsecond","Time including microseconds is outside valid range"))
return new A.bS(r,s,!1)},
A5(a){var s=Math.abs(a),r=a<0?"-":""
if(s>=1000)return""+a
if(s>=100)return r+"0"+s
if(s>=10)return r+"00"+s
return r+"000"+s},
wx(a){if(a>=100)return""+a
if(a>=10)return"0"+a
return"00"+a},
ie(a){if(a>=10)return""+a
return"0"+a},
ig(a,b){return new A.bT(a+1000*b)},
mS(a,b){var s,r,q
for(s=a.length,r=0;r<s;++r){q=a[r]
if(q.b===b)return q}throw A.c(A.aZ(b,"name","No enum value with that name"))},
ij(a){if(typeof a=="number"||A.kJ(a)||a==null)return J.bb(a)
if(typeof a=="string")return JSON.stringify(a)
return A.x3(a)},
ik(a,b){A.bA(a,"error",t.K)
A.bA(b,"stackTrace",t.l)
A.Aa(a,b)},
hV(a){return new A.hU(a)},
H(a,b){return new A.a1(!1,null,b,a)},
aZ(a,b,c){return new A.a1(!0,a,b,c)},
hQ(a,b){return a},
ay(a){var s=null
return new A.e4(s,s,!1,s,s,a)},
oc(a,b){return new A.e4(null,null,!0,a,b,"Value not in range")},
ab(a,b,c,d,e){return new A.e4(b,c,!0,a,d,"Invalid value")},
x5(a,b,c,d){if(a<b||a>c)throw A.c(A.ab(a,b,c,d,null))
return a},
aI(a,b,c){if(0>a||a>c)throw A.c(A.ab(a,0,c,"start",null))
if(b!=null){if(a>b||b>c)throw A.c(A.ab(b,a,c,"end",null))
return b}return c},
aH(a,b){if(a<0)throw A.c(A.ab(a,0,null,b,null))
return a},
wG(a,b){var s=b.b
return new A.fl(s,!0,a,null,"Index out of range")},
it(a,b,c,d,e){return new A.fl(b,!0,a,e,"Index out of range")},
Ak(a,b,c,d,e){if(0>a||a>=b)throw A.c(A.it(a,b,c,d,e==null?"index":e))
return a},
R(a){return new A.fR(a)},
vs(a){return new A.jr(a)},
z(a){return new A.aW(a)},
am(a){return new A.i9(a)},
wz(a){return new A.jW(a)},
ai(a,b,c){return new A.aT(a,b,c)},
Ao(a,b,c){var s,r
if(A.w6(a)){if(b==="("&&c===")")return"(...)"
return b+"..."+c}s=A.u([],t.s)
$.dB.push(a)
try{A.D5(a,s)}finally{$.dB.pop()}r=A.vp(b,s,", ")+c
return r.charCodeAt(0)==0?r:r},
nE(a,b,c){var s,r
if(A.w6(a))return b+"..."+c
s=new A.Z(b)
$.dB.push(a)
try{r=s
r.a=A.vp(r.a,a,", ")}finally{$.dB.pop()}s.a+=c
r=s.a
return r.charCodeAt(0)==0?r:r},
D5(a,b){var s,r,q,p,o,n,m,l=a.gA(a),k=0,j=0
for(;;){if(!(k<80||j<3))break
if(!l.l())return
s=A.q(l.gp())
b.push(s)
k+=s.length+2;++j}if(!l.l()){if(j<=5)return
r=b.pop()
q=b.pop()}else{p=l.gp();++j
if(!l.l()){if(j<=4){b.push(A.q(p))
return}r=A.q(p)
q=b.pop()
k+=r.length+2}else{o=l.gp();++j
for(;l.l();p=o,o=n){n=l.gp();++j
if(j>100){for(;;){if(!(k>75&&j>3))break
k-=b.pop().length+2;--j}b.push("...")
return}}q=A.q(p)
r=A.q(o)
k+=r.length+q.length+4}}if(j>b.length+2){k+=5
m="..."}else m=null
for(;;){if(!(k>80&&b.length>3))break
k-=b.pop().length+2
if(m==null){k+=5
m="..."}}if(m!=null)b.push(m)
b.push(q)
b.push(r)},
wQ(a,b,c,d,e){return new A.cS(a,b.h("@<0>").I(c).I(d).I(e).h("cS<1,2,3,4>"))},
c_(a,b,c,d,e,f){var s
if(B.d===c)return A.xg(J.U(a),J.U(b),$.eW())
if(B.d===d){s=J.U(a)
b=J.U(b)
c=J.U(c)
return A.fO(A.au(A.au(A.au($.eW(),s),b),c))}if(B.d===e){s=J.U(a)
b=J.U(b)
c=J.U(c)
d=J.U(d)
return A.fO(A.au(A.au(A.au(A.au($.eW(),s),b),c),d))}if(B.d===f){s=J.U(a)
b=J.U(b)
c=J.U(c)
d=J.U(d)
e=J.U(e)
return A.fO(A.au(A.au(A.au(A.au(A.au($.eW(),s),b),c),d),e))}s=J.U(a)
b=J.U(b)
c=J.U(c)
d=J.U(d)
e=J.U(e)
f=J.U(f)
f=A.fO(A.au(A.au(A.au(A.au(A.au(A.au($.eW(),s),b),c),d),e),f))
return f},
AG(a){var s,r,q=$.eW()
for(s=a.length,r=0;r<a.length;a.length===s||(0,A.a6)(a),++r)q=A.au(q,J.U(a[r]))
return A.fO(q)},
AH(a){var s,r,q,p,o
for(s=a.gA(a),r=0,q=0;s.l();){p=J.U(s.gp())
o=((p^p>>>16)>>>0)*569420461>>>0
o=((o^o>>>15)>>>0)*3545902487>>>0
r=r+((o^o>>>15)>>>0)&1073741823;++q}return A.xg(r,q,0)},
uR(a){var s=A.q(a),r=$.Df
if(r==null)A.Ej(s)
else r.$1(s)},
di(a5){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1,a2,a3=null,a4=a5.length
if(a4>=5){s=((a5.charCodeAt(4)^58)*3|a5.charCodeAt(0)^100|a5.charCodeAt(1)^97|a5.charCodeAt(2)^116|a5.charCodeAt(3)^97)>>>0
if(s===0)return A.xn(a4<a4?B.a.t(a5,0,a4):a5,5,a3).gjz()
else if(s===32)return A.xn(B.a.t(a5,5,a4),0,a3).gjz()}r=A.b4(8,0,!1,t.S)
r[0]=0
r[1]=-1
r[2]=-1
r[7]=-1
r[3]=0
r[4]=0
r[5]=a4
r[6]=a4
if(A.yq(a5,0,a4,0,r)>=14)r[7]=a4
q=r[1]
if(q>=0)if(A.yq(a5,0,q,20,r)===20)r[7]=q
p=r[2]+1
o=r[3]
n=r[4]
m=r[5]
l=r[6]
if(l<m)m=l
if(n<p)n=m
else if(n<=q)n=q+1
if(o<p)o=n
k=r[7]<0
j=a3
if(k){k=!1
if(!(p>q+3)){i=o>0
if(!(i&&o+1===n)){if(!B.a.S(a5,"\\",n))if(p>0)h=B.a.S(a5,"\\",p-1)||B.a.S(a5,"\\",p-2)
else h=!1
else h=!0
if(!h){if(!(m<a4&&m===n+2&&B.a.S(a5,"..",n)))h=m>n+2&&B.a.S(a5,"/..",m-3)
else h=!0
if(!h)if(q===4){if(B.a.S(a5,"file",0)){if(p<=0){if(!B.a.S(a5,"/",n)){g="file:///"
s=3}else{g="file://"
s=2}a5=g+B.a.t(a5,n,a4)
m+=s
l+=s
a4=a5.length
p=7
o=7
n=7}else if(n===m){++l
f=m+1
a5=B.a.c9(a5,n,m,"/");++a4
m=f}j="file"}else if(B.a.S(a5,"http",0)){if(i&&o+3===n&&B.a.S(a5,"80",o+1)){l-=3
e=n-3
m-=3
a5=B.a.c9(a5,o,n,"")
a4-=3
n=e}j="http"}}else if(q===5&&B.a.S(a5,"https",0)){if(i&&o+4===n&&B.a.S(a5,"443",o+1)){l-=4
e=n-4
m-=4
a5=B.a.c9(a5,o,n,"")
a4-=3
n=e}j="https"}k=!h}}}}if(k)return new A.bh(a4<a5.length?B.a.t(a5,0,a4):a5,q,p,o,n,m,l,j)
if(j==null)if(q>0)j=A.vJ(a5,0,q)
else{if(q===0)A.eK(a5,0,"Invalid empty scheme")
j=""}d=a3
if(p>0){c=q+3
b=c<p?A.xZ(a5,c,p-1):""
a=A.xW(a5,p,o,!1)
i=o+1
if(i<n){a0=A.vl(B.a.t(a5,i,n),a3)
d=A.tF(a0==null?A.r(A.ai("Invalid port",a5,i)):a0,j)}}else{a=a3
b=""}a1=A.xX(a5,n,m,a3,j,a!=null)
a2=m<l?A.xY(a5,m+1,l,a3):a3
return A.hD(j,b,a,d,a1,a2,l<a4?A.xV(a5,l+1,a4):a3)},
Bj(a){return A.vM(a,0,a.length,B.l,!1)},
jy(a,b,c){throw A.c(A.ai("Illegal IPv4 address, "+a,b,c))},
Bg(a,b,c,d,e){var s,r,q,p,o,n,m,l,k="invalid character"
for(s=d.$flags|0,r=b,q=r,p=0,o=0;;){n=q>=c?0:a.charCodeAt(q)
m=n^48
if(m<=9){if(o!==0||q===r){o=o*10+m
if(o<=255){++q
continue}A.jy("each part must be in the range 0..255",a,r)}A.jy("parts must not have leading zeros",a,r)}if(q===r){if(q===c)break
A.jy(k,a,q)}l=p+1
s&2&&A.B(d)
d[e+p]=o
if(n===46){if(l<4){++q
p=l
r=q
o=0
continue}break}if(q===c){if(l===4)return
break}A.jy(k,a,q)
p=l}A.jy("IPv4 address should contain exactly 4 parts",a,q)},
Bh(a,b,c){var s
if(b===c)throw A.c(A.ai("Empty IP address",a,b))
if(a.charCodeAt(b)===118){s=A.Bi(a,b,c)
if(s!=null)throw A.c(s)
return!1}A.xq(a,b,c)
return!0},
Bi(a,b,c){var s,r,q,p,o="Missing hex-digit in IPvFuture address";++b
for(s=b;;s=r){if(s<c){r=s+1
q=a.charCodeAt(s)
if((q^48)<=9)continue
p=q|32
if(p>=97&&p<=102)continue
if(q===46){if(r-1===b)return new A.aT(o,a,r)
s=r
break}return new A.aT("Unexpected character",a,r-1)}if(s-1===b)return new A.aT(o,a,s)
return new A.aT("Missing '.' in IPvFuture address",a,s)}if(s===c)return new A.aT("Missing address in IPvFuture address, host, cursor",null,null)
for(;;){if((u.S.charCodeAt(a.charCodeAt(s))&16)!==0){++s
if(s<c)continue
return null}return new A.aT("Invalid IPvFuture address character",a,s)}},
xq(a0,a1,a2){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b="an address must contain at most 8 parts",a=new A.pK(a0)
if(a2-a1<2)a.$2("address is too short",null)
s=new Uint8Array(16)
r=-1
q=0
if(a0.charCodeAt(a1)===58)if(a0.charCodeAt(a1+1)===58){p=a1+2
o=p
r=0
q=1}else{a.$2("invalid start colon",a1)
p=a1
o=p}else{p=a1
o=p}for(n=0,m=!0;;){l=p>=a2?0:a0.charCodeAt(p)
A:{k=l^48
if(k<=9)j=k
else{i=l|32
if(i>=97&&i<=102)j=i-87
else break A
m=!1}if(p<o+4){n=n*16+j;++p
continue}a.$2("an IPv6 part can contain a maximum of 4 hex digits",o)}if(p>o){if(l===46){if(m){if(q<=6){A.Bg(a0,o,a2,s,q*2)
q+=2
p=a2
break}a.$2(b,o)}break}h=q*2
s[h]=B.b.Z(n,8)
s[h+1]=n&255;++q
if(l===58){if(q<8){++p
o=p
n=0
m=!0
continue}a.$2(b,p)}break}if(l===58){if(r<0){g=q+1;++p
r=q
q=g
o=p
continue}a.$2("only one wildcard `::` is allowed",p)}if(r!==q-1)a.$2("missing part",p)
break}if(p<a2)a.$2("invalid character",p)
if(q<8){if(r<0)a.$2("an address without a wildcard must contain exactly 8 parts",a2)
f=r+1
e=q-f
if(e>0){d=f*2
c=16-e*2
B.e.Y(s,c,16,s,d)
B.e.fJ(s,d,c,0)}}return s},
hD(a,b,c,d,e,f,g){return new A.hC(a,b,c,d,e,f,g)},
xS(a){if(a==="http")return 80
if(a==="https")return 443
return 0},
eK(a,b,c){throw A.c(A.ai(c,a,b))},
Cj(a,b){var s,r,q
for(s=a.length,r=0;r<s;++r){q=a[r]
if(B.a.V(q,"/")){s=A.R("Illegal path character "+q)
throw A.c(s)}}},
tF(a,b){if(a!=null&&a===A.xS(b))return null
return a},
xW(a,b,c,d){var s,r,q,p,o,n,m,l
if(a==null)return null
if(b===c)return""
if(a.charCodeAt(b)===91){s=c-1
if(a.charCodeAt(s)!==93)A.eK(a,b,"Missing end `]` to match `[` in host")
r=b+1
q=""
if(a.charCodeAt(r)!==118){p=A.Ck(a,r,s)
if(p<s){o=p+1
q=A.y1(a,B.a.S(a,"25",o)?p+3:o,s,"%25")}s=p}n=A.Bh(a,r,s)
m=B.a.t(a,r,s)
return"["+(n?m.toLowerCase():m)+q+"]"}for(l=b;l<c;++l)if(a.charCodeAt(l)===58){s=B.a.bn(a,"%",b)
s=s>=b&&s<c?s:c
if(s<c){o=s+1
q=A.y1(a,B.a.S(a,"25",o)?s+3:o,c,"%25")}else q=""
A.xq(a,b,s)
return"["+B.a.t(a,b,s)+q+"]"}return A.Cn(a,b,c)},
Ck(a,b,c){var s=B.a.bn(a,"%",b)
return s>=b&&s<c?s:c},
y1(a,b,c,d){var s,r,q,p,o,n,m,l,k,j,i=d!==""?new A.Z(d):null
for(s=b,r=s,q=!0;s<c;){p=a.charCodeAt(s)
if(p===37){o=A.vK(a,s,!0)
n=o==null
if(n&&q){s+=3
continue}if(i==null)i=new A.Z("")
m=i.a+=B.a.t(a,r,s)
if(n)o=B.a.t(a,s,s+3)
else if(o==="%")A.eK(a,s,"ZoneID should not contain % anymore")
i.a=m+o
s+=3
r=s
q=!0}else if(p<127&&(u.S.charCodeAt(p)&1)!==0){if(q&&65<=p&&90>=p){if(i==null)i=new A.Z("")
if(r<s){i.a+=B.a.t(a,r,s)
r=s}q=!1}++s}else{l=1
if((p&64512)===55296&&s+1<c){k=a.charCodeAt(s+1)
if((k&64512)===56320){p=65536+((p&1023)<<10)+(k&1023)
l=2}}j=B.a.t(a,r,s)
if(i==null){i=new A.Z("")
n=i}else n=i
n.a+=j
m=A.vI(p)
n.a+=m
s+=l
r=s}}if(i==null)return B.a.t(a,b,c)
if(r<c){j=B.a.t(a,r,c)
i.a+=j}n=i.a
return n.charCodeAt(0)==0?n:n},
Cn(a,b,c){var s,r,q,p,o,n,m,l,k,j,i,h=u.S
for(s=b,r=s,q=null,p=!0;s<c;){o=a.charCodeAt(s)
if(o===37){n=A.vK(a,s,!0)
m=n==null
if(m&&p){s+=3
continue}if(q==null)q=new A.Z("")
l=B.a.t(a,r,s)
if(!p)l=l.toLowerCase()
k=q.a+=l
j=3
if(m)n=B.a.t(a,s,s+3)
else if(n==="%"){n="%25"
j=1}q.a=k+n
s+=j
r=s
p=!0}else if(o<127&&(h.charCodeAt(o)&32)!==0){if(p&&65<=o&&90>=o){if(q==null)q=new A.Z("")
if(r<s){q.a+=B.a.t(a,r,s)
r=s}p=!1}++s}else if(o<=93&&(h.charCodeAt(o)&1024)!==0)A.eK(a,s,"Invalid character")
else{j=1
if((o&64512)===55296&&s+1<c){i=a.charCodeAt(s+1)
if((i&64512)===56320){o=65536+((o&1023)<<10)+(i&1023)
j=2}}l=B.a.t(a,r,s)
if(!p)l=l.toLowerCase()
if(q==null){q=new A.Z("")
m=q}else m=q
m.a+=l
k=A.vI(o)
m.a+=k
s+=j
r=s}}if(q==null)return B.a.t(a,b,c)
if(r<c){l=B.a.t(a,r,c)
if(!p)l=l.toLowerCase()
q.a+=l}m=q.a
return m.charCodeAt(0)==0?m:m},
vJ(a,b,c){var s,r,q
if(b===c)return""
if(!A.xU(a.charCodeAt(b)))A.eK(a,b,"Scheme not starting with alphabetic character")
for(s=b,r=!1;s<c;++s){q=a.charCodeAt(s)
if(!(q<128&&(u.S.charCodeAt(q)&8)!==0))A.eK(a,s,"Illegal scheme character")
if(65<=q&&q<=90)r=!0}a=B.a.t(a,b,c)
return A.Ci(r?a.toLowerCase():a)},
Ci(a){if(a==="http")return"http"
if(a==="file")return"file"
if(a==="https")return"https"
if(a==="package")return"package"
return a},
xZ(a,b,c){if(a==null)return""
return A.hE(a,b,c,16,!1,!1)},
xX(a,b,c,d,e,f){var s,r=e==="file",q=r||f
if(a==null)return r?"/":""
else s=A.hE(a,b,c,128,!0,!0)
if(s.length===0){if(r)return"/"}else if(q&&!B.a.K(s,"/"))s="/"+s
return A.Cm(s,e,f)},
Cm(a,b,c){var s=b.length===0
if(s&&!c&&!B.a.K(a,"/")&&!B.a.K(a,"\\"))return A.vL(a,!s||c)
return A.dy(a)},
xY(a,b,c,d){if(a!=null)return A.hE(a,b,c,256,!0,!1)
return null},
xV(a,b,c){if(a==null)return null
return A.hE(a,b,c,256,!0,!1)},
vK(a,b,c){var s,r,q,p,o,n=b+2
if(n>=a.length)return"%"
s=a.charCodeAt(b+1)
r=a.charCodeAt(n)
q=A.uw(s)
p=A.uw(r)
if(q<0||p<0)return"%"
o=q*16+p
if(o<127&&(u.S.charCodeAt(o)&1)!==0)return A.aQ(c&&65<=o&&90>=o?(o|32)>>>0:o)
if(s>=97||r>=97)return B.a.t(a,b,b+3).toUpperCase()
return null},
vI(a){var s,r,q,p,o,n="0123456789ABCDEF"
if(a<=127){s=new Uint8Array(3)
s[0]=37
s[1]=n.charCodeAt(a>>>4)
s[2]=n.charCodeAt(a&15)}else{if(a>2047)if(a>65535){r=240
q=4}else{r=224
q=3}else{r=192
q=2}s=new Uint8Array(3*q)
for(p=0;--q,q>=0;r=128){o=B.b.mh(a,6*q)&63|r
s[p]=37
s[p+1]=n.charCodeAt(o>>>4)
s[p+2]=n.charCodeAt(o&15)
p+=3}}return A.bI(s,0,null)},
hE(a,b,c,d,e,f){var s=A.y0(a,b,c,d,e,f)
return s==null?B.a.t(a,b,c):s},
y0(a,b,c,d,e,f){var s,r,q,p,o,n,m,l,k,j=null,i=u.S
for(s=!e,r=b,q=r,p=j;r<c;){o=a.charCodeAt(r)
if(o<127&&(i.charCodeAt(o)&d)!==0)++r
else{n=1
if(o===37){m=A.vK(a,r,!1)
if(m==null){r+=3
continue}if("%"===m)m="%25"
else n=3}else if(o===92&&f)m="/"
else if(s&&o<=93&&(i.charCodeAt(o)&1024)!==0){A.eK(a,r,"Invalid character")
n=j
m=n}else{if((o&64512)===55296){l=r+1
if(l<c){k=a.charCodeAt(l)
if((k&64512)===56320){o=65536+((o&1023)<<10)+(k&1023)
n=2}}}m=A.vI(o)}if(p==null){p=new A.Z("")
l=p}else l=p
l.a=(l.a+=B.a.t(a,q,r))+m
r+=n
q=r}}if(p==null)return j
if(q<c){s=B.a.t(a,q,c)
p.a+=s}s=p.a
return s.charCodeAt(0)==0?s:s},
y_(a){if(B.a.K(a,"."))return!0
return B.a.c7(a,"/.")!==-1},
dy(a){var s,r,q,p,o,n
if(!A.y_(a))return a
s=A.u([],t.s)
for(r=a.split("/"),q=r.length,p=!1,o=0;o<q;++o){n=r[o]
if(n===".."){if(s.length!==0){s.pop()
if(s.length===0)s.push("")}p=!0}else{p="."===n
if(!p)s.push(n)}}if(p)s.push("")
return B.c.bp(s,"/")},
vL(a,b){var s,r,q,p,o,n
if(!A.y_(a))return!b?A.xT(a):a
s=A.u([],t.s)
for(r=a.split("/"),q=r.length,p=!1,o=0;o<q;++o){n=r[o]
if(".."===n){if(s.length!==0&&B.c.gaP(s)!=="..")s.pop()
else s.push("..")
p=!0}else{p="."===n
if(!p)s.push(n.length===0&&s.length===0?"./":n)}}if(s.length===0)return"./"
if(p)s.push("")
if(!b)s[0]=A.xT(s[0])
return B.c.bp(s,"/")},
xT(a){var s,r,q=a.length
if(q>=2&&A.xU(a.charCodeAt(0)))for(s=1;s<q;++s){r=a.charCodeAt(s)
if(r===58)return B.a.t(a,0,s)+"%3A"+B.a.a1(a,s+1)
if(r>127||(u.S.charCodeAt(r)&8)===0)break}return a},
Co(a,b){if(a.eg("package")&&a.c==null)return A.ys(b,0,b.length)
return-1},
Cl(a,b){var s,r,q
for(s=0,r=0;r<2;++r){q=a.charCodeAt(b+r)
if(48<=q&&q<=57)s=s*16+q-48
else{q|=32
if(97<=q&&q<=102)s=s*16+q-87
else throw A.c(A.H("Invalid URL encoding",null))}}return s},
vM(a,b,c,d,e){var s,r,q,p,o=b
for(;;){if(!(o<c)){s=!0
break}r=a.charCodeAt(o)
if(r<=127)q=r===37
else q=!0
if(q){s=!1
break}++o}if(s)if(B.l===d)return B.a.t(a,b,c)
else p=new A.bn(B.a.t(a,b,c))
else{p=A.u([],t.t)
for(q=a.length,o=b;o<c;++o){r=a.charCodeAt(o)
if(r>127)throw A.c(A.H("Illegal percent encoding in URI",null))
if(r===37){if(o+3>q)throw A.c(A.H("Truncated URI",null))
p.push(A.Cl(a,o+1))
o+=2}else p.push(r)}}return d.aI(p)},
xU(a){var s=a|32
return 97<=s&&s<=122},
xn(a,b,c){var s,r,q,p,o,n,m,l,k="Invalid MIME type",j=A.u([b-1],t.t)
for(s=a.length,r=b,q=-1,p=null;r<s;++r){p=a.charCodeAt(r)
if(p===44||p===59)break
if(p===47){if(q<0){q=r
continue}throw A.c(A.ai(k,a,r))}}if(q<0&&r>b)throw A.c(A.ai(k,a,r))
while(p!==44){j.push(r);++r
for(o=-1;r<s;++r){p=a.charCodeAt(r)
if(p===61){if(o<0)o=r}else if(p===59||p===44)break}if(o>=0)j.push(o)
else{n=B.c.gaP(j)
if(p!==44||r!==n+7||!B.a.S(a,"base64",n+1))throw A.c(A.ai("Expecting '='",a,r))
break}}j.push(r)
m=r+1
if((j.length&1)===1)a=B.aM.oj(a,m,s)
else{l=A.y0(a,m,s,256,!0,!1)
if(l!=null)a=B.a.c9(a,m,s,l)}return new A.pJ(a,j,c)},
yq(a,b,c,d,e){var s,r,q
for(s=b;s<c;++s){r=a.charCodeAt(s)^96
if(r>95)r=31
q='\xe1\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\xe1\xe1\xe1\x01\xe1\xe1\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\xe1\xe3\xe1\xe1\x01\xe1\x01\xe1\xcd\x01\xe1\x01\x01\x01\x01\x01\x01\x01\x01\x0e\x03\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01"\x01\xe1\x01\xe1\xac\xe1\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\xe1\xe1\xe1\x01\xe1\xe1\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\xe1\xea\xe1\xe1\x01\xe1\x01\xe1\xcd\x01\xe1\x01\x01\x01\x01\x01\x01\x01\x01\x01\n\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01"\x01\xe1\x01\xe1\xac\xeb\x8b\x8b\x8b\x8b\x8b\x8b\x8b\x8b\x8b\x8b\x8b\x8b\x8b\x8b\x8b\x8b\x8b\x8b\x8b\x8b\x8b\x8b\x8b\x8b\x8b\x8b\xeb\xeb\xeb\x8b\xeb\xeb\x8b\x8b\x8b\x8b\x8b\x8b\x8b\x8b\x8b\x8b\x8b\x8b\x8b\x8b\x8b\x8b\x8b\x8b\x8b\x8b\x8b\x8b\x8b\x8b\x8b\x8b\xeb\x83\xeb\xeb\x8b\xeb\x8b\xeb\xcd\x8b\xeb\x8b\x8b\x8b\x8b\x8b\x8b\x8b\x8b\x92\x83\x8b\x8b\x8b\x8b\x8b\x8b\x8b\x8b\x8b\x8b\xeb\x8b\xeb\x8b\xeb\xac\xeb\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\xeb\xeb\xeb\v\xeb\xeb\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\xebD\xeb\xeb\v\xeb\v\xeb\xcd\v\xeb\v\v\v\v\v\v\v\v\x12D\v\v\v\v\v\v\v\v\v\v\xeb\v\xeb\v\xeb\xac\xe5\x05\x05\x05\x05\x05\x05\x05\x05\x05\x05\x05\x05\x05\x05\x05\x05\x05\x05\x05\x05\x05\x05\x05\x05\x05\x05\xe5\xe5\xe5\x05\xe5D\xe5\xe5\xe5\xe5\xe5\xe5\xe5\xe5\xe5\xe5\xe5\xe5\xe5\xe5\xe5\xe5\xe5\xe5\xe5\xe5\xe5\xe5\xe5\xe5\xe5\xe5\xe8\x8a\xe5\xe5\x05\xe5\x05\xe5\xcd\x05\xe5\x05\x05\x05\x05\x05\x05\x05\x05\x05\x8a\x05\x05\x05\x05\x05\x05\x05\x05\x05\x05f\x05\xe5\x05\xe5\xac\xe5\x05\x05\x05\x05\x05\x05\x05\x05\x05\x05\x05\x05\x05\x05\x05\x05\x05\x05\x05\x05\x05\x05\x05\x05\x05\x05\xe5\xe5\xe5\x05\xe5D\xe5\xe5\xe5\xe5\xe5\xe5\xe5\xe5\xe5\xe5\xe5\xe5\xe5\xe5\xe5\xe5\xe5\xe5\xe5\xe5\xe5\xe5\xe5\xe5\xe5\xe5\xe5\x8a\xe5\xe5\x05\xe5\x05\xe5\xcd\x05\xe5\x05\x05\x05\x05\x05\x05\x05\x05\x05\x8a\x05\x05\x05\x05\x05\x05\x05\x05\x05\x05f\x05\xe5\x05\xe5\xac\xe7\xe7\xe7\xe7\xe7\xe7\xe7\xe7\xe7\xe7\xe7\xe7\xe7\xe7\xe7\xe7\xe7\xe7\xe7\xe7\xe7\xe7\xe7\xe7\xe7\xe7\xe7\xe7\xe7\xe7\xe7\xe7D\xe7\xe7\xe7\xe7\xe7\xe7\xe7\xe7\xe7\xe7\xe7\xe7\xe7\xe7\xe7\xe7\xe7\xe7\xe7\xe7\xe7\xe7\xe7\xe7\xe7\xe7\xe7\x8a\xe7\xe7\xe7\xe7\xe7\xe7\xcd\xe7\xe7\xe7\xe7\xe7\xe7\xe7\xe7\xe7\xe7\xe7\x8a\xe7\x07\x07\x07\x07\x07\x07\x07\x07\x07\xe7\xe7\xe7\xe7\xe7\xac\xe7\xe7\xe7\xe7\xe7\xe7\xe7\xe7\xe7\xe7\xe7\xe7\xe7\xe7\xe7\xe7\xe7\xe7\xe7\xe7\xe7\xe7\xe7\xe7\xe7\xe7\xe7\xe7\xe7\xe7\xe7\xe7D\xe7\xe7\xe7\xe7\xe7\xe7\xe7\xe7\xe7\xe7\xe7\xe7\xe7\xe7\xe7\xe7\xe7\xe7\xe7\xe7\xe7\xe7\xe7\xe7\xe7\xe7\xe7\x8a\xe7\xe7\xe7\xe7\xe7\xe7\xcd\xe7\xe7\xe7\xe7\xe7\xe7\xe7\xe7\xe7\xe7\xe7\x8a\x07\x07\x07\x07\x07\x07\x07\x07\x07\x07\xe7\xe7\xe7\xe7\xe7\xac\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\x05\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\xeb\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\xeb\xeb\xeb\v\xeb\xeb\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\xeb\xea\xeb\xeb\v\xeb\v\xeb\xcd\v\xeb\v\v\v\v\v\v\v\v\x10\xea\v\v\v\v\v\v\v\v\v\v\xeb\v\xeb\v\xeb\xac\xeb\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\xeb\xeb\xeb\v\xeb\xeb\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\xeb\xea\xeb\xeb\v\xeb\v\xeb\xcd\v\xeb\v\v\v\v\v\v\v\v\x12\n\v\v\v\v\v\v\v\v\v\v\xeb\v\xeb\v\xeb\xac\xeb\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\xeb\xeb\xeb\v\xeb\xeb\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\xeb\xea\xeb\xeb\v\xeb\v\xeb\xcd\v\xeb\v\v\v\v\v\v\v\v\v\n\v\v\v\v\v\v\v\v\v\v\xeb\v\xeb\v\xeb\xac\xec\f\f\f\f\f\f\f\f\f\f\f\f\f\f\f\f\f\f\f\f\f\f\f\f\f\f\xec\xec\xec\f\xec\xec\f\f\f\f\f\f\f\f\f\f\f\f\f\f\f\f\f\f\f\f\f\f\f\f\f\f\xec\xec\xec\xec\f\xec\f\xec\xcd\f\xec\f\f\f\f\f\f\f\f\f\xec\f\f\f\f\f\f\f\f\f\f\xec\f\xec\f\xec\f\xed\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\xed\xed\xed\r\xed\xed\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\r\xed\xed\xed\xed\r\xed\r\xed\xed\r\xed\r\r\r\r\r\r\r\r\r\xed\r\r\r\r\r\r\r\r\r\r\xed\r\xed\r\xed\r\xe1\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\xe1\xe1\xe1\x01\xe1\xe1\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\xe1\xea\xe1\xe1\x01\xe1\x01\xe1\xcd\x01\xe1\x01\x01\x01\x01\x01\x01\x01\x01\x0f\xea\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01"\x01\xe1\x01\xe1\xac\xe1\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\xe1\xe1\xe1\x01\xe1\xe1\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\xe1\xe9\xe1\xe1\x01\xe1\x01\xe1\xcd\x01\xe1\x01\x01\x01\x01\x01\x01\x01\x01\x01\t\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01"\x01\xe1\x01\xe1\xac\xeb\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\xeb\xeb\xeb\v\xeb\xeb\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\xeb\xea\xeb\xeb\v\xeb\v\xeb\xcd\v\xeb\v\v\v\v\v\v\v\v\x11\xea\v\v\v\v\v\v\v\v\v\v\xeb\v\xeb\v\xeb\xac\xeb\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\xeb\xeb\xeb\v\xeb\xeb\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\xeb\xe9\xeb\xeb\v\xeb\v\xeb\xcd\v\xeb\v\v\v\v\v\v\v\v\v\t\v\v\v\v\v\v\v\v\v\v\xeb\v\xeb\v\xeb\xac\xeb\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\xeb\xeb\xeb\v\xeb\xeb\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\xeb\xea\xeb\xeb\v\xeb\v\xeb\xcd\v\xeb\v\v\v\v\v\v\v\v\x13\xea\v\v\v\v\v\v\v\v\v\v\xeb\v\xeb\v\xeb\xac\xeb\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\xeb\xeb\xeb\v\xeb\xeb\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\v\xeb\xea\xeb\xeb\v\xeb\v\xeb\xcd\v\xeb\v\v\v\v\v\v\v\v\v\xea\v\v\v\v\v\v\v\v\v\v\xeb\v\xeb\v\xeb\xac\xf5\x15\x15\x15\x15\x15\x15\x15\x15\x15\x15\x15\x15\x15\x15\x15\x15\x15\x15\x15\x15\x15\x15\x15\x15\x15\x15\xf5\xf5\xf5\xf5\xf5\xf5\xf5\xf5\xf5\xf5\xf5\xf5\xf5\xf5\xf5\xf5\xf5\xf5\xf5\xf5\xf5\xf5\xf5\xf5\xf5\xf5\xf5\xf5\xf5\xf5\xf5\xf5\xf5\xf5\xf5\xf5\xf5\xf5\xf5\xf5\xf5\xf5\xf5\xf5\xf5\xf5\xf5\xf5\xf5\xf5\xf5\xf5\xf5\xf5\xf5\xf5\xf5\xf5\xf5\xf5\xf5\xf5\xf5\xf5\xf5\xf5\xf5\xf5\xf5\xf5\x15\x15\x15\x15\x15\x15\x15\x15\x15\x15\x15\x15\x15\x15\x15\x15\x15\x15\x15\x15\x15\x15\x15\x15\x15\x15\xf5\xf5\xf5\xf5\xf5\xf5\xf5\xf5\xf5\xf5\xf5\xf5\xf5\xf5\xf5\xf5\xf5\xf5\xf5\xf5\xf5\xf5\xf5\xf5\xf5\xf5\xf5\xf5\xf5\xf5\xf5\xf5\xf5\xf5\xf5\xf5\xf5\xf5\xf5\xf5\xf5\xf5\xf5\xf5\xf5\xf5\xf5\xf5\x15\xf5\x15\x15\xf5\x15\x15\x15\x15\x15\x15\x15\x15\x15\x15\xf5\xf5\xf5\xf5\xf5\xf5'.charCodeAt(d*96+r)
d=q&31
e[q>>>5]=s}return d},
xK(a){if(a.b===7&&B.a.K(a.a,"package")&&a.c<=0)return A.ys(a.a,a.e,a.f)
return-1},
ys(a,b,c){var s,r,q
for(s=b,r=0;s<c;++s){q=a.charCodeAt(s)
if(q===47)return r!==0?s:-1
if(q===37||q===58)return-1
r|=q^46}return-1},
y9(a,b,c){var s,r,q,p,o,n
for(s=a.length,r=0,q=0;q<s;++q){p=b.charCodeAt(c+q)
o=a.charCodeAt(q)^p
if(o!==0){if(o===32){n=p|o
if(97<=n&&n<=122){r=32
continue}}return-1}}return r},
az:function az(a,b,c){this.a=a
this.b=b
this.c=c},
qT:function qT(){},
qU:function qU(){},
jX:function jX(a,b){this.a=a
this.$ti=b},
bS:function bS(a,b,c){this.a=a
this.b=b
this.c=c},
bT:function bT(a){this.a=a},
rp:function rp(){},
V:function V(){},
hU:function hU(a){this.a=a},
c3:function c3(){},
a1:function a1(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=d},
e4:function e4(a,b,c,d,e,f){var _=this
_.e=a
_.f=b
_.a=c
_.b=d
_.c=e
_.d=f},
fl:function fl(a,b,c,d,e){var _=this
_.f=a
_.a=b
_.b=c
_.c=d
_.d=e},
fR:function fR(a){this.a=a},
jr:function jr(a){this.a=a},
aW:function aW(a){this.a=a},
i9:function i9(a){this.a=a},
iT:function iT(){},
fI:function fI(){},
jW:function jW(a){this.a=a},
aT:function aT(a,b,c){this.a=a
this.b=b
this.c=c},
iv:function iv(){},
m:function m(){},
K:function K(a,b,c){this.a=a
this.b=b
this.$ti=c},
D:function D(){},
k:function k(){},
ku:function ku(){},
Z:function Z(a){this.a=a},
pK:function pK(a){this.a=a},
hC:function hC(a,b,c,d,e,f,g){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e
_.f=f
_.r=g
_.y=_.x=_.w=$},
pJ:function pJ(a,b,c){this.a=a
this.b=b
this.c=c},
bh:function bh(a,b,c,d,e,f,g,h){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e
_.f=f
_.r=g
_.w=h
_.x=null},
jT:function jT(a,b,c,d,e,f,g){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e
_.f=f
_.r=g
_.y=_.x=_.w=$},
im:function im(a){this.a=a},
yb(a,b,c,d){if(a)return""+d+"-"+c+"-begin"
if(b)return""+d+"-"+c+"-end"
return c},
ym(a){var s=$.eM.i(0,a)
if(s==null)return a
return a+"-"+A.q(s)},
CG(a){var s,r
if(!$.eM.F(a))return
s=$.eM.i(0,a)
s.toString
r=s-1
s=$.eM
if(r<=0)s.H(0,a)
else s.m(0,a,r)},
Ft(a,b,c,d,e){var s,r,q,p,o,n
if(c===9||c===11||c===10)return
if($.eO>1e4&&$.eM.a===0){$.kV().clearMarks()
$.kV().clearMeasures()
$.eO=0}s=c===1||c===5
r=c===2||c===7
q=A.yb(s,r,d,a)
if(s){p=$.eM.i(0,q)
if(p==null)p=0
$.eM.m(0,q,p+1)
q=A.ym(q)}o=$.kV()
o.toString
o.mark(q,$.zn().parse(e))
$.eO=$.eO+1
if(r){n=A.yb(!0,!1,d,a)
o=$.kV()
o.toString
o.measure(d,A.ym(n),q)
$.eO=$.eO+1
A.CG(n)}B.b.mN($.eO,0,10001)},
Fg(a){if(a==null||a.a===0)return"{}"
return B.h.b9(a)},
u2:function u2(){},
u0:function u0(){},
vw:function vw(a,b){this.a=a
this.b=b},
yF(){return v.G},
Az(a){return a},
Ar(a){return a},
At(a){return a},
vq(a){return a},
CF(a,b){var s,r,q
if(t.mT.b(a))return a
s=t.g.a(v.G.Error)
r=A.q(a)
r=A.DF(s,["Wrapped Dart error thrown from converted Future. See 'error'and 'stack' properties.\n"+r])
if(t.d9.b(a))A.r("Attempting to box non-Dart object.")
q={}
q[$.zm()]=a
r.error=q
r.stack=b.j(0)
return r},
wE(a){return new v.G.Promise(A.aY(new A.n0(a)))},
iR:function iR(a){this.a=a},
n0:function n0(a){this.a=a},
mZ:function mZ(a){this.a=a},
n_:function n_(a){this.a=a},
kH(a){var s
if(typeof a=="function")throw A.c(A.H("Attempting to rewrap a JS function.",null))
s=function(b,c){return function(){return b(c)}}(A.Cw,a)
s[$.dH()]=a
return s},
bz(a){var s
if(typeof a=="function")throw A.c(A.H("Attempting to rewrap a JS function.",null))
s=function(b,c){return function(d){return b(c,d,arguments.length)}}(A.Cx,a)
s[$.dH()]=a
return s},
aY(a){var s
if(typeof a=="function")throw A.c(A.H("Attempting to rewrap a JS function.",null))
s=function(b,c){return function(d,e){return b(c,d,e,arguments.length)}}(A.Cy,a)
s[$.dH()]=a
return s},
kI(a){var s
if(typeof a=="function")throw A.c(A.H("Attempting to rewrap a JS function.",null))
s=function(b,c){return function(d,e,f){return b(c,d,e,f,arguments.length)}}(A.Cz,a)
s[$.dH()]=a
return s},
dz(a){var s
if(typeof a=="function")throw A.c(A.H("Attempting to rewrap a JS function.",null))
s=function(b,c){return function(d,e,f,g){return b(c,d,e,f,g,arguments.length)}}(A.CA,a)
s[$.dH()]=a
return s},
vU(a){var s
if(typeof a=="function")throw A.c(A.H("Attempting to rewrap a JS function.",null))
s=function(b,c){return function(d,e,f,g,h){return b(c,d,e,f,g,h,arguments.length)}}(A.CB,a)
s[$.dH()]=a
return s},
Cw(a){return a.$0()},
Cx(a,b,c){if(c>=1)return a.$1(b)
return a.$0()},
Cy(a,b,c,d){if(d>=2)return a.$2(b,c)
if(d===1)return a.$1(b)
return a.$0()},
Cz(a,b,c,d,e){if(e>=3)return a.$3(b,c,d)
if(e===2)return a.$2(b,c)
if(e===1)return a.$1(b)
return a.$0()},
CA(a,b,c,d,e,f){if(f>=4)return a.$4(b,c,d,e)
if(f===3)return a.$3(b,c,d)
if(f===2)return a.$2(b,c)
if(f===1)return a.$1(b)
return a.$0()},
CB(a,b,c,d,e,f,g){if(g>=5)return a.$5(b,c,d,e,f)
if(g===4)return a.$4(b,c,d,e)
if(g===3)return a.$3(b,c,d)
if(g===2)return a.$2(b,c)
if(g===1)return a.$1(b)
return a.$0()},
yj(a){return a==null||A.kJ(a)||typeof a=="number"||typeof a=="string"||t.jx.b(a)||t.p.b(a)||t.nn.b(a)||t.m6.b(a)||t.i7.b(a)||t.bW.b(a)||t.mC.b(a)||t.pk.b(a)||t.kI.b(a)||t.lo.b(a)||t.fW.b(a)},
Ea(a){if(A.yj(a))return a
return new A.uB(new A.dt(t.mp)).$1(a)},
uu(a,b){return a[b]},
yz(a,b,c){return a[b].apply(a,c)},
DF(a,b){var s,r
if(b==null)return new a()
if(b instanceof Array)switch(b.length){case 0:return new a()
case 1:return new a(b[0])
case 2:return new a(b[0],b[1])
case 3:return new a(b[0],b[1],b[2])
case 4:return new a(b[0],b[1],b[2],b[3])}s=[null]
B.c.a7(s,b)
r=a.bind.apply(a,s)
String(r)
return new r()},
aq(a,b){var s=new A.l($.o,b.h("l<0>")),r=new A.a9(s,b.h("a9<0>"))
a.then(A.dD(new A.uS(r),1),A.dD(new A.uT(r),1))
return s},
uB:function uB(a){this.a=a},
uS:function uS(a){this.a=a},
uT:function uT(a){this.a=a},
yJ(a,b){return Math.max(a,b)},
AO(){return B.b3},
rY:function rY(){},
rZ:function rZ(a){this.a=a},
ii:function ii(a,b){this.a=a
this.b=b},
fV:function fV(a){this.a=a},
fJ:function fJ(a,b,c){var _=this
_.a=$
_.b=!1
_.c=a
_.e=b
_.$ti=c},
oJ:function oJ(){},
oK:function oK(a,b){this.a=a
this.b=b},
oI:function oI(){},
oH:function oH(a){this.a=a},
oG:function oG(a,b){this.a=a
this.b=b},
eG:function eG(a){this.a=a},
S:function S(){},
lw:function lw(a){this.a=a},
lx:function lx(a){this.a=a},
ly:function ly(a,b){this.a=a
this.b=b},
lz:function lz(a){this.a=a},
lA:function lA(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=d},
fa:function fa(){},
eJ:function eJ(){},
db:function db(a){this.$ti=a},
eB:function eB(a,b,c){this.a=a
this.b=b
this.c=c},
iI:function iI(a){this.$ti=a},
wU(){throw A.c(A.R(u.O))},
iP:function iP(){},
ju:function ju(){},
EP(a){return new A.cv("Request aborted by `abortTrigger`",a)},
l1:function l1(){},
cv:function cv(a,b){this.a=a
this.b=b},
hY:function hY(){},
hZ:function hZ(){},
le:function le(){},
lf:function lf(){},
lg:function lg(){},
yu(a,b){var s
if(t.m.b(a)&&"AbortError"===a.name)return new A.cv("Request aborted by `abortTrigger`",b.b)
if(!(a instanceof A.bQ)){s=J.bb(a)
if(B.a.K(s,"TypeError: "))s=B.a.a1(s,11)
a=new A.bQ(s,b.b)}return a},
yo(a,b,c){A.ik(A.yu(a,c),b)},
Cv(a,b){return new A.bx(!1,new A.tS(a,b),t.fb)},
eQ(a,b,c){return A.Dh(a,b,c)},
Dh(a,a0,a1){var s=0,r=A.i(t.H),q,p=2,o=[],n,m,l,k,j,i,h,g,f,e,d,c,b
var $async$eQ=A.d(function(a2,a3){if(a2===1){o.push(a3)
s=p}for(;;)switch(s){case 0:e={}
d=a0.body
c=d==null?null:d.getReader()
s=c==null?3:4
break
case 3:s=5
return A.b(a1.n(),$async$eQ)
case 5:s=1
break
case 4:e.a=null
e.b=e.c=!1
a1.f=new A.u3(e)
a1.r=new A.u4(e,c,a)
d=t.Z,k=t.m,j=t.D,i=t.h
case 6:n=null
p=9
s=12
return A.b(A.aq(c.read(),k),$async$eQ)
case 12:n=a3
p=2
s=11
break
case 9:p=8
b=o.pop()
m=A.E(b)
l=A.M(b)
s=!e.c?13:14
break
case 13:e.b=!0
d=A.yu(m,a)
k=l
j=a1.b
if(j>=4)A.r(a1.aq())
if((j&1)!==0){j=a1.ga6()
j.ab(d,k==null?B.t:k)}s=15
return A.b(a1.n(),$async$eQ)
case 15:case 14:s=7
break
s=11
break
case 8:s=2
break
case 11:if(n.done){a1.iP()
s=7
break}else{g=n.value
g.toString
d.a(g)
f=a1.b
if(f>=4)A.r(a1.aq())
if((f&1)!==0)a1.ga6().N(g)}g=a1.b
s=((g&1)!==0?(a1.ga6().e&4)!==0:(g&2)===0)?16:17
break
case 16:g=e.a
s=18
return A.b((g==null?e.a=new A.a9(new A.l($.o,j),i):g).a,$async$eQ)
case 18:case 17:if((a1.b&1)===0){s=7
break}s=6
break
case 7:case 1:return A.f(q,r)
case 2:return A.e(o.at(-1),r)}})
return A.h($async$eQ,r)},
i2:function i2(a){this.b=!1
this.c=a},
lk:function lk(a){this.a=a},
ll:function ll(a){this.a=a},
tS:function tS(a,b){this.a=a
this.b=b},
u3:function u3(a){this.a=a},
u4:function u4(a,b,c){this.a=a
this.b=b
this.c=c},
cQ:function cQ(a){this.a=a},
lv:function lv(a){this.a=a},
wu(a,b){return new A.bQ(a,b)},
bQ:function bQ(a,b){this.a=a
this.b=b},
v2(a,b,c){var s=new Uint8Array(0),r=$.yZ()
if(!r.b.test(a))A.r(A.aZ(a,"method","Not a valid method"))
r=t.N
return new A.hP(c,s,a,b,A.vi(new A.le(),new A.lf(),r,r))},
op:function op(){},
hP:function hP(a,b,c,d,e){var _=this
_.cx=a
_.y=b
_.a=c
_.b=d
_.r=e
_.w=!1},
jG:function jG(){},
j3(a){var s=0,r=A.i(t.b),q,p,o,n,m,l,k,j
var $async$j3=A.d(function(b,c){if(b===1)return A.e(c,r)
for(;;)switch(s){case 0:s=3
return A.b(a.w.h5(),$async$j3)
case 3:p=c
o=a.b
n=a.a
m=a.e
l=a.c
k=A.yV(p)
j=p.length
k=new A.e6(k,n,o,l,j,m,!1,!0)
k.eO(o,j,m,!1,!0,l,n)
q=k
s=1
break
case 1:return A.f(q,r)}})
return A.h($async$j3,r)},
vQ(a){var s=a.i(0,"content-type")
if(s!=null)return A.wR(s)
return A.nS("application","octet-stream",null)},
e6:function e6(a,b,c,d,e,f,g,h){var _=this
_.w=a
_.a=b
_.b=c
_.c=d
_.d=e
_.e=f
_.f=g
_.r=h},
B4(a,b,c,d,e,f,g,h){var s=new A.cz(A.yU(a),h,b,g,c,d,!1,!0)
s.eO(b,c,d,!1,!0,g,h)
return s},
cz:function cz(a,b,c,d,e,f,g,h){var _=this
_.w=a
_.a=b
_.b=c
_.c=d
_.d=e
_.e=f
_.f=g
_.r=h},
jl:function jl(a,b,c,d,e,f,g,h){var _=this
_.w=a
_.a=b
_.b=c
_.c=d
_.d=e
_.e=f
_.f=g
_.r=h},
zP(a){return a.toLowerCase()},
f0:function f0(a,b,c){this.a=a
this.c=b
this.$ti=c},
wR(a){return A.Ey("media type",a,new A.nT(a))},
nS(a,b,c){var s=t.N
if(c==null)s=A.T(s,s)
else{s=new A.f0(A.DG(),A.T(s,t.gc),t.kj)
s.a7(0,c)}return new A.fv(a.toLowerCase(),b.toLowerCase(),new A.dh(s,t.ph))},
fv:function fv(a,b,c){this.a=a
this.b=b
this.c=c},
nT:function nT(a){this.a=a},
nV:function nV(a){this.a=a},
nU:function nU(){},
DT(a){var s
a.iZ($.zq(),"quoted string")
s=a.gfV().i(0,0)
return A.yR(B.a.t(s,1,s.length-1),$.zp(),new A.up(),null)},
up:function up(){},
cq:function cq(a,b){this.a=a
this.b=b},
dX:function dX(a,b,c,d,e,f){var _=this
_.a=a
_.b=b
_.d=c
_.e=d
_.r=e
_.w=f},
vk(a){return $.AB.cB(a,new A.nN(a))},
wP(a,b,c){var s=new A.dY(a,b,c)
if(b==null)s.c=B.m
else b.d.m(0,a,s)
return s},
dY:function dY(a,b,c){var _=this
_.a=a
_.b=b
_.c=null
_.d=c
_.f=null},
nN:function nN(a){this.a=a},
yl(a){return a},
yv(a,b){var s,r,q,p,o,n,m,l
for(s=b.length,r=1;r<s;++r){if(b[r]==null||b[r-1]!=null)continue
for(;s>=1;s=q){q=s-1
if(b[q]!=null)break}p=new A.Z("")
o=a+"("
p.a=o
n=A.a5(b)
m=n.h("dd<1>")
l=new A.dd(b,0,s,m)
l.kJ(b,0,s,n.c)
m=o+new A.a8(l,new A.uh(),m.h("a8<X.E,j>")).bp(0,", ")
p.a=m
p.a=m+("): part "+(r-1)+" was null, but part "+r+" was not.")
throw A.c(A.H(p.j(0),null))}},
lY:function lY(a){this.a=a},
lZ:function lZ(){},
m_:function m_(){},
uh:function uh(){},
nD:function nD(){},
iU(a,b){var s,r,q,p,o,n=b.kc(a)
b.bI(a)
if(n!=null)a=B.a.a1(a,n.length)
s=t.s
r=A.u([],s)
q=A.u([],s)
s=a.length
if(s!==0&&b.bo(a.charCodeAt(0))){q.push(a[0])
p=1}else{q.push("")
p=0}for(o=p;o<s;++o)if(b.bo(a.charCodeAt(o))){r.push(B.a.t(a,p,o))
q.push(a[o])
p=o+1}if(p<s){r.push(B.a.a1(a,p))
q.push("")}return new A.o_(b,n,r,q)},
o_:function o_(a,b,c,d){var _=this
_.a=a
_.b=b
_.d=c
_.e=d},
wV(a){return new A.iV(a)},
iV:function iV(a){this.a=a},
B6(){var s,r,q,p,o,n,m,l,k=null
if(A.vt().gao()!=="file")return $.hL()
if(!B.a.bF(A.vt().gaQ(),"/"))return $.hL()
s=A.xZ(k,0,0)
r=A.xW(k,0,0,!1)
q=A.xY(k,0,0,k)
p=A.xV(k,0,0)
o=A.tF(k,"")
if(r==null)if(s.length===0)n=o!=null
else n=!0
else n=!1
if(n)r=""
n=r==null
m=!n
l=A.xX("a/b",0,3,k,"",m)
if(n&&!B.a.K(l,"/"))l=A.vL(l,m)
else l=A.dy(l)
if(A.hD("",s,n&&B.a.K(l,"//")?"":r,o,l,q,p).h6()==="a\\b")return $.kT()
return $.z2()},
pa:function pa(){},
o0:function o0(a,b,c){this.d=a
this.e=b
this.f=c},
pL:function pL(a,b,c,d){var _=this
_.d=a
_.e=b
_.f=c
_.r=d},
qe:function qe(a,b,c,d){var _=this
_.d=a
_.e=b
_.f=c
_.r=d},
zL(){var s=$.o,r=t.D,q=t.h,p=new A.a9(new A.l(s,r),q),o=A.bp(t.A)
o.q(0,p)
return new A.hO(p,o,new A.a9(new A.l(s,r),q))},
hO:function hO(a,b,c){this.a=a
this.b=b
this.c=c},
l_:function l_(a,b,c){this.a=a
this.b=b
this.c=c},
l0:function l0(a,b){this.a=a
this.b=b},
ct:function ct(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=d},
Bf(a){switch(a){case"PUT":return B.bU
case"PATCH":return B.bT
case"DELETE":return B.bS
default:return null}},
f8:function f8(a,b,c,d,e,f,g,h){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e
_.f=f
_.r=g
_.w=h},
fT:function fT(a,b,c){this.c=a
this.a=b
this.b=c},
Ei(a){var s=a.$ti.h("aL<C.T,bc>"),r=s.h("cf<C.T>")
return new A.cT(new A.cf(new A.uP(),new A.aL(new A.uQ(),a,s),r),r.h("cT<C.T,I>"))},
uQ:function uQ(){},
uP:function uP(){},
v5(a){return new A.f7(a)},
pc(a){return A.B9(a)},
B9(a){var s=0,r=A.i(t.jM),q,p=2,o=[],n,m,l,k
var $async$pc=A.d(function(b,c){if(b===1){o.push(c)
s=p}for(;;)switch(s){case 0:p=4
s=7
return A.b(B.l.mW(a.w),$async$pc)
case 7:n=c
m=A.xc(a,n)
q=m
s=1
break
p=2
s=6
break
case 4:p=3
k=o.pop()
if(t.L.b(A.E(k))){q=A.xd(a)
s=1
break}else throw k
s=6
break
case 3:s=2
break
case 6:case 1:return A.f(q,r)
case 2:return A.e(o.at(-1),r)}})
return A.h($async$pc,r)},
xe(a){var s,r,q
try{s=A.w2(A.vQ(a.e)).aI(a.w)
r=A.xc(a,s)
return r}catch(q){if(t.L.b(A.E(q)))return A.xd(a)
else throw q}},
xc(a,b){var s,r,q=J.eX(B.h.c5(b,null),"error")
A:{if(t.f.b(q)){s=A.B8(q)
break A}s=null
break A}r=s==null?b:s
s=a.c
if(s==null)s="Request failed"
return new A.de(a.b,s+": "+r)},
xd(a){var s=a.c
if(s==null)s="Request failed"
return new A.de(a.b,s)},
B8(a){var s,r=a.i(0,"code"),q=a.i(0,"description"),p=a.i(0,"name"),o=a.i(0,"details")
if(typeof r!="string"||typeof q!="string")return null
s=(typeof p=="string"?r+("("+p+")"):r)+": "+q
if(typeof o=="string")s=s+", "+o
return s.charCodeAt(0)==0?s:s},
f7:function f7(a){this.a=a},
e2:function e2(a){this.a=a},
de:function de(a,b){this.a=a
this.b=b},
D8(){var s=A.wP("PowerSync",null,A.T(t.N,t.W))
if(s.b!=null)A.r(A.R('Please set "hierarchicalLoggingEnabled" to true if you want to change the level on a non-root logger.'))
J.A(s.c,B.p)
s.c=B.p
s.f8().O(new A.u1())
return s},
u1:function u1(){},
d0:function d0(a){this.a=a},
vT(a){var s,r,q,p=A.bp(t.N)
for(s=a.gA(a);s.l();){r=s.gp()
q=A.DV(r)
if(q!=null)p.q(0,q)
else if(!B.a.K(r,"ps_"))p.q(0,r)}return p},
bc:function bc(a){this.a=a},
i3(a,b){var s=0,r=A.i(t.G),q
var $async$i3=A.d(function(c,d){if(c===1)return A.e(d,r)
for(;;)switch(s){case 0:s=3
return A.b(a.aC(b,B.n),$async$i3)
case 3:q=d
s=1
break
case 1:return A.f(q,r)}})
return A.h($async$i3,r)},
lo(a){var s=0,r=A.i(t.N),q,p
var $async$lo=A.d(function(b,c){if(b===1)return A.e(c,r)
for(;;)switch(s){case 0:s=3
return A.b(A.i3(a,"SELECT powersync_client_id() as client_id"),$async$lo)
case 3:p=c
q=A.ak(p.gai(p).i(0,"client_id"))
s=1
break
case 1:return A.f(q,r)}})
return A.h($async$lo,r)},
v3(a,b,c,d){return a.mB(new A.lt(b,d),c,d)},
f_(a,b){var s=0,r=A.i(t.y),q,p,o,n,m
var $async$f_=A.d(function(c,d){if(c===1)return A.e(d,r)
for(;;)switch(s){case 0:s=3
return A.b(a.ow(new A.lr(),t.I),$async$f_)
case 3:p=d
if(p==null){q=!1
s=1
break}o=a
n=A
m=p
s=5
return A.b(b.$0(),$async$f_)
case 5:s=4
return A.b(o.b_(new n.ls(m,d),t.y),$async$f_)
case 4:q=d
s=1
break
case 1:return A.f(q,r)}})
return A.h($async$f_,r)},
lq(a){var s=0,r=A.i(t.d_),q,p,o,n,m,l,k,j,i,h,g
var $async$lq=A.d(function(b,c){if(b===1)return A.e(c,r)
for(;;)switch(s){case 0:s=3
return A.b(a.dA("SELECT * FROM ps_crud ORDER BY id ASC LIMIT 1"),$async$lq)
case 3:g=c
if(g==null)p=null
else{o=B.h.c5(A.ak(g.i(0,"data")),null)
p=A.O(g.i(0,"id"))
n=J.aa(o)
m=A.Bf(A.ak(n.i(o,"op")))
m.toString
l=A.ak(n.i(o,"type"))
k=A.ak(n.i(o,"id"))
j=A.O(g.i(0,"tx_id"))
i=t.h9
h=i.a(n.i(o,"data"))
i=i.a(n.i(o,"old"))
i=new A.f8(p,j,m,l,k,A.kE(n.i(o,"metadata")),h,i)
p=i}q=p
s=1
break
case 1:return A.f(q,r)}})
return A.h($async$lq,r)},
lp(a){var s=0,r=A.i(t.y),q,p
var $async$lp=A.d(function(b,c){if(b===1)return A.e(c,r)
for(;;)switch(s){case 0:s=3
return A.b(A.i3(a,"SELECT 1 FROM ps_crud LIMIT 1"),$async$lp)
case 3:p=c
q=!p.gE(p)
s=1
break
case 1:return A.f(q,r)}})
return A.h($async$lp,r)},
lm(a,b,c){var s=0,r=A.i(t.N),q
var $async$lm=A.d(function(d,e){if(d===1)return A.e(e,r)
for(;;)switch(s){case 0:s=3
return A.b(a.b_(new A.ln(b,c),t.N),$async$lm)
case 3:q=e
s=1
break
case 1:return A.f(q,r)}})
return A.h($async$lm,r)},
iX(a,b,c){var s=0,r=A.i(t.T),q,p
var $async$iX=A.d(function(d,e){if(d===1)return A.e(e,r)
for(;;)switch(s){case 0:p=A
s=3
return A.b(a.bw("SELECT CAST(powersync_control(?, ?) AS TEXT)",[b,c]),$async$iX)
case 3:q=p.kE(e.b[0])
s=1
break
case 1:return A.f(q,r)}})
return A.h($async$iX,r)},
d6(a,b,c){var s=0,r=A.i(t.T),q
var $async$d6=A.d(function(d,e){if(d===1)return A.e(e,r)
for(;;)switch(s){case 0:s=3
return A.b(A.iX(a,b+"_checkpoint_request_id",c),$async$d6)
case 3:q=e
s=1
break
case 1:return A.f(q,r)}})
return A.h($async$d6,r)},
o2(a){var s=0,r=A.i(t.N),q,p
var $async$o2=A.d(function(b,c){if(b===1)return A.e(c,r)
for(;;)switch(s){case 0:s=3
return A.b(A.d6(a,"next",null),$async$o2)
case 3:p=c
p.toString
q=p
s=1
break
case 1:return A.f(q,r)}})
return A.h($async$o2,r)},
lt:function lt(a,b){this.a=a
this.b=b},
lr:function lr(){},
ls:function ls(a,b){this.a=a
this.b=b},
ln:function ln(a,b){this.a=a
this.b=b},
dL:function dL(a){this.a=a},
lF:function lF(a,b,c){this.a=a
this.b=b
this.c=c},
lG:function lG(a,b){this.a=a
this.b=b},
cb:function cb(){},
hl:function hl(){},
en:function en(a){this.a=a},
h7:function h7(){},
Am(a){return A.Al(a)},
Al(a){var s,r,q,p,o,n,m,l,k,j="UpdateSyncStatus",i="EstablishSyncStream",h="FetchCredentials",g="CloseSyncStream",f="DidCompleteSync",e="CheckpointDelayedDueToLocalData",d="HandleDiagnostics"
A:{s=a.i(0,"LogLine")
if(s==null)r=a.F("LogLine")
else r=!0
if(r){t.f.a(s)
r=new A.ft(A.ak(s.i(0,"severity")),A.ak(s.i(0,"line")))
break A}q=a.i(0,j)
if(q==null)r=a.F(j)
else r=!0
if(r){r=t.f
r=new A.fS(A.A2(r.a(r.a(q).i(0,"status"))))
break A}p=a.i(0,i)
if(p==null)r=a.F(i)
else r=!0
if(r){r=A.Ab(t.f.a(p))
break A}o=a.i(0,h)
if(o==null)r=a.F(h)
else r=!0
if(r){r=new A.ff(A.aX(t.f.a(o).i(0,"did_expire")))
break A}n=a.i(0,g)
if(n==null)r=a.F(g)
else r=!0
if(r){t.f.a(n)
r=new A.dM(A.aX(n.i(0,"hide_disconnect")))
break A}m=a.i(0,f)
if(m==null)r=a.F(f)
else r=!0
if(r){r=B.aP
break A}l=a.i(0,e)
if(l==null)r=a.F(e)
else r=!0
if(r){r=B.aO
break A}k=a.i(0,d)
if(k==null)r=a.F(d)
else r=!0
if(r){r=new A.fj(t.f.a(k))
break A}r=new A.fQ(a)
break A}return r},
Ab(a){var s=t.f,r=s.a(a.i(0,"request")),q=a.i(0,"checkpoint_request")
A:{if(q==null){s=null
break A}s.a(q)
s=new A.lE(A.ak(q.i(0,"client_id")),A.ak(q.i(0,"checkpoint_request_id")))
break A}return new A.dR(r,s)},
A2(a){var s,r,q,p,o,n=A.aX(a.i(0,"connected"))
A.aX(a.i(0,"connecting"))
s=A.u([],t.cH)
for(r=J.a0(t.j.a(a.i(0,"priority_status"))),q=t.f;r.l();)s.push(A.A3(q.a(r.gp())))
p=a.i(0,"downloading")
A:{if(p==null)break A
A.A6(q.a(p))
break A}s=J.dI(t.ia.a(a.i(0,"streams")),new A.m2(),t.em)
A.an(s,s.$ti.h("X.E"))
o=A.kE(a.i(0,"internal_last_applied_checkpoint_request_id"))
B:{if(o==null){s=null
break B}s=new A.d0(v.G.BigInt(o))
break B}return new A.m1(a,n,s)},
A3(a){var s,r=A.O(a.i(0,"priority")),q=A.vN(a.i(0,"has_synced")),p=a.i(0,"last_synced_at")
A:{if(p==null){s=null
break A}s=A.mN(A.O(p))
break A}return new A.ki(q,s,r)},
A6(a){return new A.mO(t.f.a(a.i(0,"buckets")).cz(0,new A.mP(),t.N,t.cV))},
ft:function ft(a,b){this.a=a
this.b=b},
dR:function dR(a,b){this.a=a
this.b=b},
lE:function lE(a,b){this.a=a
this.b=b},
fS:function fS(a){this.a=a},
m1:function m1(a,b,c){this.a=a
this.b=b
this.r=c},
m2:function m2(){},
mO:function mO(a){this.a=a},
mP:function mP(){},
ff:function ff(a){this.a=a},
dM:function dM(a){this.a=a},
fb:function fb(){},
f2:function f2(){},
fj:function fj(a){this.a=a},
fQ:function fQ(a){this.a=a},
nC:function nC(a,b){this.a=a
this.b=b},
AS(a){var s=a.a
return s==null?B.L:s},
AT(a){var s=a.b
return s==null?B.K:s},
fN:function fN(a,b,c,d,e,f,g,h,i){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e
_.f=f
_.r=g
_.w=h
_.x=i},
lD:function lD(){},
fr:function fr(){},
d9:function d9(a){this.a=a},
pb:function pb(a,b){this.a=a
this.b=b},
xf(a,b){if(B.v.D(0,b))return null
else return b==null?a:b},
aK:function aK(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=d},
pj:function pj(){},
A1(a){var s,r,q,p,o,n,m,l,k,j,i=A.ak(a.i(0,"name")),h=t.h9.a(a.i(0,"parameters")),g=A.vO(a.i(0,"priority"))
A:{if(g!=null){s=g
break A}s=2147483647
break A}r=t.f.a(a.i(0,"progress"))
q=A.O(r.i(0,"total"))
r=A.O(r.i(0,"downloaded"))
p=A.aX(a.i(0,"active"))
o=A.aX(a.i(0,"is_default"))
n=A.aX(a.i(0,"has_explicit_subscription"))
m=a.i(0,"expires_at")
B:{if(m==null){l=null
break B}l=A.mN(A.O(m))
break B}k=a.i(0,"last_synced_at")
C:{if(k==null){j=null
break C}j=A.mN(A.O(k))
break C}return new A.dP(i,h,s,new A.kd(r,q),p,o,n,l,j)},
dP:function dP(a,b,c,d,e,f,g,h,i){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e
_.f=f
_.r=g
_.w=h
_.x=i},
yK(a,b){var s=null,r={},q=A.bH(s,s,s,s,!0,b)
r.a=null
r.b=!1
q.d=new A.uJ(r,a,q,b)
q.r=new A.uK(r)
q.e=new A.uL(r)
q.f=new A.uM(r)
return new A.a4(q,A.p(q).h("a4<1>"))},
Eh(a){var s,r
for(s=a.length,r=0;r<a.length;a.length===s||(0,A.a6)(a),++r)a[r].aj()},
Em(a){var s,r
for(s=a.length,r=0;r<a.length;a.length===s||(0,A.a6)(a),++r)a[r].am()},
kL(a){var s=0,r=A.i(t.H)
var $async$kL=A.d(function(b,c){if(b===1)return A.e(c,r)
for(;;)switch(s){case 0:s=2
return A.b(A.n4(new A.a8(a,new A.uk(),A.a5(a).h("a8<1,n<~>>")),t.H),$async$kL)
case 2:return A.f(null,r)}})
return A.h($async$kL,r)},
Ep(a,b){var s=null,r={},q=A.bH(s,s,s,s,!0,b)
r.a=!1
q.r=new A.uY(r,a.bc(new A.uZ(q,b),new A.v_(r,q),t.P))
return new A.a4(q,A.p(q).h("a4<1>"))},
Bk(a,b,c,d,e,f){var s=new A.l($.o,t.D),r=new A.a9(s,t.h),q=a.O(null),p=new A.pM(e,r,q,f)
q.bt(p)
p.$1(c)
b.J(new A.pN(r,d,q))
return s},
BF(a){return new A.em(a,new DataView(new ArrayBuffer(4)))},
uJ:function uJ(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=d},
uI:function uI(a,b,c){this.a=a
this.b=b
this.c=c},
uG:function uG(a,b){this.a=a
this.b=b},
uH:function uH(a,b){this.a=a
this.b=b},
uK:function uK(a){this.a=a},
uL:function uL(a){this.a=a},
uM:function uM(a){this.a=a},
uk:function uk(){},
uZ:function uZ(a,b){this.a=a
this.b=b},
v_:function v_(a,b){this.a=a
this.b=b},
uY:function uY(a,b){this.a=a
this.b=b},
pM:function pM(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=d},
pN:function pN(a,b,c){this.a=a
this.b=b
this.c=c},
em:function em(a,b){var _=this
_.a=a
_.b=b
_.c=4
_.d=null},
vR(a){var s,r={},q=new A.l($.o,t.D)
r.a=null
s=new A.tY(r,new A.L(q,t.F))
r.a=A.jq(a,s)
return new A.N(q,s)},
Du(a){var s="Sync service error"
if(a instanceof A.bQ)return s
else if(a instanceof A.de)if(a.a===401)return"Authorization error"
else return s
else if(a instanceof A.a1||t.lW.b(a))return"Configuration error"
else if(a instanceof A.f7)return"Credentials error"
else if(a instanceof A.e2)return"Protocol error"
else return J.wi(a).j(0)+": "+A.q(a)},
AQ(a){return new A.cu(a)},
eN(a,b){if((a.a.a.a&30)===0)return!1
return b instanceof A.bQ||b instanceof A.bB},
oV:function oV(a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e
_.f=f
_.r=g
_.w=h
_.x=i
_.y=j
_.z=null
_.Q=k
_.as=l
_.at=null
_.ax=m
_.ay=n
_.ch=o
_.CW=p
_.cx=null},
p8:function p8(a,b){this.a=a
this.b=b},
oY:function oY(a,b,c){this.a=a
this.b=b
this.c=c},
oZ:function oZ(a){this.a=a},
oW:function oW(a,b,c){this.a=a
this.b=b
this.c=c},
p7:function p7(a,b,c){this.a=a
this.b=b
this.c=c},
p6:function p6(a,b){this.a=a
this.b=b},
p5:function p5(){},
p_:function p_(a){this.a=a},
p0:function p0(a,b,c){this.a=a
this.b=b
this.c=c},
p1:function p1(a){this.a=a},
p4:function p4(a,b,c){this.a=a
this.b=b
this.c=c},
p2:function p2(a,b){this.a=a
this.b=b},
p3:function p3(){},
oX:function oX(a,b){this.a=a
this.b=b},
tY:function tY(a,b){this.a=a
this.b=b},
qu:function qu(a,b,c){var _=this
_.a=a
_.b=b
_.c=c
_.d=!1},
qv:function qv(){},
qB:function qB(a){this.a=a},
qA:function qA(a){this.a=a},
qz:function qz(){},
qw:function qw(a,b){this.a=a
this.b=b},
qx:function qx(a){this.a=a},
qy:function qy(a){this.a=a},
dO:function dO(a,b){this.a=a
this.b=b},
cu:function cu(a){this.a=a},
fU:function fU(){},
fP:function fP(){},
fi:function fi(a){this.a=a},
f3:function f3(a,b){this.a=a
this.b=b},
C6(a,b){var s=null,r=new A.kk(a,b,A.bH(s,s,s,s,!0,t.p))
r.kR(a,b)
return r},
e5:function e5(a){this.a=a
this.b=0},
oo:function oo(a,b){this.a=a
this.b=b},
kk:function kk(a,b,c){var _=this
_.a=a
_.b=b
_.c=c
_.d=!1},
td:function td(a){this.a=a},
EO(a){var s
if(t.p.b(a)){s=B.e.gau(a)
if(a.byteOffset===0&&J.zF(s)===a.length)return t.a.a(s)}return t.a.a(B.e.gau(new Uint8Array(A.vS(a))))},
vm:function vm(a){this.a=a},
vE:function vE(a){this.a=!1
this.b=a
this.c=null},
A_(a,b){var s=new A.ck(b)
s.kF(a,b)
return s},
Ba(a){var s=null,r=new A.fJ(B.aG,A.T(t.ir,t.mQ),t.a9),q=t.pp
r.a=A.bH(r.gml(),r.glP(),r.gmm(),r.gmo(),!0,q)
q=new A.ee(a,new A.fN(s,s,s,s,B.ao,s,s,s,!0),r,A.bH(s,s,s,s,!1,q),{},A.T(t.hM,t.eL),A.u([],t.bN))
q.kK(a)
return q},
pk:function pk(a){this.a=a},
pl:function pl(a){this.a=a},
ck:function ck(a){var _=this
_.a=$
_.b=a
_.f=_.e=_.d=_.c=null},
lV:function lV(a){this.a=a},
lU:function lU(a){this.a=a},
lW:function lW(a){this.a=a},
ee:function ee(a,b,c,d,e,f,g){var _=this
_.a=a
_.b=b
_.c="{}"
_.d=c
_.e=d
_.f=null
_.r=e
_.w=null
_.x=f
_.y=g},
pi:function pi(a){this.a=a},
pd:function pd(a,b,c){this.a=a
this.b=b
this.c=c},
pe:function pe(a,b,c){this.a=a
this.b=b
this.c=c},
pf:function pf(a){this.a=a},
pg:function pg(a){this.a=a},
ph:function ph(a){this.a=a},
fY:function fY(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=d},
hr:function hr(a){this.a=a},
h6:function h6(a){this.a=a},
h3:function h3(a,b){this.a=a
this.b=b},
xm(a){var s=a.content
s=B.c.ba(s,new A.pI(),t.E)
s=A.an(s,s.$ti.h("X.E"))
return s},
x7(a){var s,r,q=a.endpoint,p=a.token,o=a.userId
if(o==null)o=null
if(a.expiresAt==null)s=null
else{s=a.expiresAt
s.toString
s=A.mN(A.O(s))}r=A.di(q)
if(!r.eg("http")&&!r.eg("https")||r.gbH().length===0)A.r(A.aZ(q,"PowerSync endpoint must be a valid URL",null))
return new A.ct(q,p,o,s)},
x8(a){var s,r
A:{if(a==null){s=null
break A}if(B.v.D(0,a)){s=-1
break A}r=J.bb(a)
s=r
break A}return s},
Bm(a,b){var s=null,r=t.S,q=$.o,p=A.bH(s,s,s,s,!1,t.l4),o=$.we()
r=new A.jE(A.T(r,t.kn),A.T(r,t.A),new A.a9(new A.l(q,t.D),t.h),a,b,p,o,s)
r.kM(s,s,s,a,b)
return r},
ad:function ad(a,b){this.a=a
this.b=b},
pI:function pI(){},
jE:function jE(a,b,c,d,e,f,g,h){var _=this
_.a=a
_.b=b
_.c=c
_.d=0
_.f=_.e=!1
_.w=_.r=null
_.y=d
_.z=e
_.Q=f
_.as=g
_.at=h},
qk:function qk(a){this.a=a},
qf:function qf(){},
qg:function qg(a,b){this.a=a
this.b=b},
qh:function qh(a,b){this.a=a
this.b=b},
qi:function qi(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=d},
qj:function qj(a,b){this.a=a
this.b=b},
oe:function oe(a){this.a=a},
j2:function j2(a){this.a=a},
i6:function i6(){},
Ec(){var s=null,r=v.G,q=r.location.href,p=t.m,o=A.bH(s,s,s,s,!0,p),n=t.cj
new A.ql(new A.rq(new A.o3(new A.rn(q)),new A.a4(o,A.p(o).h("a4<1>"))),new A.o1(),A.u([],t.az),A.T(t.S,t.lp),new A.dZ(A.nL(n)),new A.dZ(A.nL(n))).cu()
if($.zl())A.aC(r,"connect",new A.uC(new A.uE(new A.uD(new A.pk(A.T(t.N,t.mO)),o))),!1,p)
else A.aC(r,"message",o.gc4(o),!1,p)},
uD:function uD(a,b){this.a=a
this.b=b},
uE:function uE(a){this.a=a},
uC:function uC(a){this.a=a},
rq:function rq(a,b){this.a=a
this.b=b},
o1:function o1(){},
o3:function o3(a){this.a=a},
v8(a,b){if(b<0)A.r(A.ay("Offset may not be negative, was "+b+"."))
else if(b>a.c.length)A.r(A.ay("Offset "+b+u.D+a.gk(0)+"."))
return new A.iq(a,b)},
oy:function oy(a,b,c){var _=this
_.a=a
_.b=b
_.c=c
_.d=null},
iq:function iq(a,b){this.a=a
this.b=b},
ew:function ew(a,b,c){this.a=a
this.b=b
this.c=c},
Ag(a,b){var s=A.Ah(A.u([A.BL(a,!0)],t.g7)),r=new A.ns(b).$0(),q=B.b.j(B.c.gaP(s).b+1),p=A.Ai(s)?0:3,o=A.a5(s)
return new A.n8(s,r,null,1+Math.max(q.length,p),new A.a8(s,new A.na(),o.h("a8<1,a>")).ox(0,B.aL),!A.E7(new A.a8(s,new A.nb(),o.h("a8<1,k?>"))),new A.Z(""))},
Ai(a){var s,r,q
for(s=0;s<a.length-1;){r=a[s];++s
q=a[s]
if(r.b+1!==q.b&&J.A(r.c,q.c))return!1}return!0},
Ah(a){var s,r,q=A.DY(a,new A.nd(),t.nf,t.K)
for(s=new A.b3(q,q.r,q.e);s.l();)J.wj(s.d,new A.ne())
s=A.p(q).h("aF<1,2>")
r=s.h("fe<m.E,bw>")
s=A.an(new A.fe(new A.aF(q,s),new A.nf(),r),r.h("m.E"))
return s},
BL(a,b){var s=new A.rP(a).$0()
return new A.aP(s,!0,null)},
BN(a){var s,r,q,p,o,n,m=a.gah()
if(!B.a.V(m,"\r\n"))return a
s=a.gC().gaa()
for(r=m.length-1,q=0;q<r;++q)if(m.charCodeAt(q)===13&&m.charCodeAt(q+1)===10)--s
r=a.gG()
p=a.gM()
o=a.gC().gX()
p=A.j9(s,a.gC().ga8(),o,p)
o=A.hK(m,"\r\n","\n")
n=a.gaH()
return A.oz(r,p,o,A.hK(n,"\r\n","\n"))},
BO(a){var s,r,q,p,o,n,m
if(!B.a.bF(a.gaH(),"\n"))return a
if(B.a.bF(a.gah(),"\n\n"))return a
s=B.a.t(a.gaH(),0,a.gaH().length-1)
r=a.gah()
q=a.gG()
p=a.gC()
if(B.a.bF(a.gah(),"\n")){o=A.uq(a.gaH(),a.gah(),a.gG().ga8())
o.toString
o=o+a.gG().ga8()+a.gk(a)===a.gaH().length}else o=!1
if(o){r=B.a.t(a.gah(),0,a.gah().length-1)
if(r.length===0)p=q
else{o=a.gC().gaa()
n=a.gM()
m=a.gC().gX()
p=A.j9(o-1,A.xE(s),m-1,n)
q=a.gG().gaa()===a.gC().gaa()?p:a.gG()}}return A.oz(q,p,r,s)},
BM(a){var s,r,q,p,o
if(a.gC().ga8()!==0)return a
if(a.gC().gX()===a.gG().gX())return a
s=B.a.t(a.gah(),0,a.gah().length-1)
r=a.gG()
q=a.gC().gaa()
p=a.gM()
o=a.gC().gX()
p=A.j9(q-1,s.length-B.a.cw(s,"\n")-1,o-1,p)
return A.oz(r,p,s,B.a.bF(a.gaH(),"\n")?B.a.t(a.gaH(),0,a.gaH().length-1):a.gaH())},
xE(a){var s=a.length
if(s===0)return 0
else if(a.charCodeAt(s-1)===10)return s===1?0:s-B.a.eh(a,"\n",s-2)-1
else return s-B.a.cw(a,"\n")-1},
n8:function n8(a,b,c,d,e,f,g){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e
_.f=f
_.r=g},
ns:function ns(a){this.a=a},
na:function na(){},
n9:function n9(){},
nb:function nb(){},
nd:function nd(){},
ne:function ne(){},
nf:function nf(){},
nc:function nc(a){this.a=a},
nt:function nt(){},
ng:function ng(a){this.a=a},
nn:function nn(a,b,c){this.a=a
this.b=b
this.c=c},
no:function no(a,b){this.a=a
this.b=b},
np:function np(a){this.a=a},
nq:function nq(a,b,c,d,e,f,g){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e
_.f=f
_.r=g},
nl:function nl(a,b){this.a=a
this.b=b},
nm:function nm(a,b){this.a=a
this.b=b},
nh:function nh(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=d},
ni:function ni(a,b,c){this.a=a
this.b=b
this.c=c},
nj:function nj(a,b,c){this.a=a
this.b=b
this.c=c},
nk:function nk(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=d},
nr:function nr(a,b,c){this.a=a
this.b=b
this.c=c},
aP:function aP(a,b,c){this.a=a
this.b=b
this.c=c},
rP:function rP(a){this.a=a},
bw:function bw(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=d},
j9(a,b,c,d){if(a<0)A.r(A.ay("Offset may not be negative, was "+a+"."))
else if(c<0)A.r(A.ay("Line may not be negative, was "+c+"."))
else if(b<0)A.r(A.ay("Column may not be negative, was "+b+"."))
return new A.bt(d,a,c,b)},
bt:function bt(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=d},
ja:function ja(){},
jc:function jc(){},
B2(a,b,c){return new A.e8(c,a,b)},
jd:function jd(){},
e8:function e8(a,b,c){this.c=a
this.a=b
this.b=c},
e9:function e9(){},
oz(a,b,c,d){var s=new A.c1(d,a,b,c)
s.kI(a,b,c)
if(!B.a.V(d,c))A.r(A.H('The context line "'+d+'" must contain "'+c+'".',null))
if(A.uq(d,c,a.ga8())==null)A.r(A.H('The span text "'+c+'" must start at column '+(a.ga8()+1)+' in a line within "'+d+'".',null))
return s},
c1:function c1(a,b,c,d){var _=this
_.d=a
_.a=b
_.b=c
_.c=d},
B3(a){var s
switch(a){case 18:s=B.aj
break
case 23:s=B.ak
break
case 9:s=B.al
break
default:s=null
break}return s},
eb:function eb(a,b){this.a=a
this.b=b},
b7:function b7(a,b,c){this.a=a
this.b=b
this.c=c},
cx:function cx(){},
jj:function jj(a,b){this.a=a
this.b=b},
ea:function ea(a,b){this.a=a
this.b=b},
ji:function ji(a){this.a=a},
jh(a,b,c,d,e,f,g){return new A.dc(d,b,c,e,f,a,g)},
dc:function dc(a,b,c,d,e,f,g){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e
_.f=f
_.r=g},
oE:function oE(){},
mw:function mw(a,b,c){var _=this
_.a=a
_.b=b
_.c=c
_.r=_.f=_.e=_.d=null
_.w=!1},
mF:function mF(a){this.a=a},
mE:function mE(a){this.a=a},
mG:function mG(a){this.a=a},
mC:function mC(a){this.a=a},
mB:function mB(a){this.a=a},
mD:function mD(a){this.a=a},
my:function my(a){this.a=a},
mx:function mx(a){this.a=a},
mz:function mz(a){this.a=a},
mA:function mA(a,b){this.a=a
this.b=b},
cF:function cF(a,b,c,d,e){var _=this
_.a=a
_.b=!1
_.c=b
_.d=null
_.e=c
_.f=d
_.w=_.r=null
_.$ti=e},
to:function to(a,b){this.a=a
this.b=b},
tp:function tp(a,b,c){this.a=a
this.b=b
this.c=c},
tq:function tq(a,b,c){this.a=a
this.b=b
this.c=c},
oA:function oA(){},
ed:function ed(a,b,c){var _=this
_.a=a
_.b=b
_.d=c
_.e=null
_.f=!0
_.r=!1},
vb(a,b){var s=$.kS()
return new A.is(A.T(t.N,t.a_),s,a)},
is:function is(a,b,c){this.d=a
this.b=b
this.a=c},
k0:function k0(a,b,c){var _=this
_.a=a
_.b=b
_.c=c
_.d=0},
Eg(a){var s=J.zJ(new v.G.URL(a,"file:///").pathname,"/")
return new A.c7(s,new A.uO(),A.a5(s).h("c7<1>"))},
uO:function uO(){},
m3:function m3(){},
bF:function bF(a,b,c){this.d=a
this.a=b
this.c=c},
aV:function aV(a,b){this.a=a
this.b=b},
kl:function kl(a){this.a=a
this.b=-1},
km:function km(){},
kn:function kn(){},
ko:function ko(){},
kp:function kp(){},
nZ:function nZ(a,b){this.a=a
this.b=b},
AP(a){var s=a.f=!1,r=a.a
r=r.c.d.sqlite3_step(r.b)
A:{if(100===r){s=!0
break A}if(101===r||0===r)break A
s=a.bv(r,"step")}return s},
cV:function cV(){},
nx:function nx(){},
f9:function f9(a){this.a=a},
c6(a){return new A.c5(a)},
wm(a,b){var s,r,q,p
if(b==null)b=$.kS()
for(s=a.length,r=a.$flags|0,q=0;q<s;++q){p=b.en(256)
r&2&&A.B(a)
a[q]=p}},
c5:function c5(a){this.a=a},
fH:function fH(a){this.a=a},
aB:function aB(){},
i0:function i0(){},
i_:function i_(){},
En(a,b){var s=null,r=new A.d3(t.kk)
return A.Eo(a,new A.qq(s,s,s,s,s,s,s,s,new A.uV(new A.uU(r,A.kH(new A.uW(r)))),s,s,s,s),b)},
dl:function dl(a){var _=this
_.d=a
_.c=_.b=_.a=null},
uW:function uW(a){this.a=a},
uU:function uU(a,b){this.a=a
this.b=b},
uV:function uV(a){this.a=a},
pY:function pY(a,b){this.a=a
this.b=b},
pT:function pT(a,b,c){this.a=a
this.b=b
this.c=c},
q_:function q_(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=d},
pZ:function pZ(a,b,c){this.b=a
this.c=b
this.d=c},
dj:function dj(){},
cA:function cA(){},
ei:function ei(a,b,c){this.a=a
this.b=b
this.c=c},
cg(a,b){var s,r,q,p,o=null
try{o=a.$0()}catch(q){s=A.E(q)
r=A.M(q)
p=$.o
p.b1(p,s,r)
o=b}return o},
aS(a){var s,r,q,p=0
try{a.$0()}catch(r){q=A.E(r)
if(q instanceof A.c5){s=q
p=s.a}else{A.M(r)
p=1}}return p},
ib:function ib(a){this.b=this.a=$
this.d=a},
mf:function mf(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=d},
mb:function mb(a,b,c,d,e){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e},
mk:function mk(a,b,c,d,e){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e},
mm:function mm(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=d},
mp:function mp(a,b){this.a=a
this.b=b},
me:function me(a,b,c){this.a=a
this.b=b
this.c=c},
md:function md(a){this.a=a},
mn:function mn(a,b,c,d,e){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e},
mt:function mt(a,b,c,d,e){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e},
mr:function mr(a,b){this.a=a
this.b=b},
mq:function mq(a,b){this.a=a
this.b=b},
mj:function mj(a,b,c){this.a=a
this.b=b
this.c=c},
mi:function mi(a,b,c){this.a=a
this.b=b
this.c=c},
ml:function ml(a,b){this.a=a
this.b=b},
ms:function ms(a,b){this.a=a
this.b=b},
mc:function mc(a,b,c){this.a=a
this.b=b
this.c=c},
mg:function mg(a){this.a=a},
mh:function mh(a,b,c){this.a=a
this.b=b
this.c=c},
mo:function mo(a){this.a=a},
m9:function m9(a,b,c,d,e){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e},
m8:function m8(a,b,c){this.a=a
this.b=b
this.c=c},
ma:function ma(a,b,c,d,e,f){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e
_.f=f},
m7:function m7(a,b){this.a=a
this.b=b},
m6:function m6(a,b){this.a=a
this.b=b},
m5:function m5(a,b,c){this.a=a
this.b=b
this.c=c},
eY:function eY(a,b){this.a=a
this.$ti=b},
l2:function l2(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=d},
l4:function l4(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=d},
l3:function l3(a,b,c){this.a=a
this.b=b
this.c=c},
bC(a,b){var s=new A.l($.o,b.h("l<0>")),r=new A.L(s,b.h("L<0>")),q=t.m
A.aC(a,"success",new A.lM(r,a,b),!1,q)
A.aC(a,"error",new A.lN(r,a),!1,q)
return s},
zZ(a,b){var s=new A.l($.o,b.h("l<0>")),r=new A.L(s,b.h("L<0>")),q=t.m
A.aC(a,"success",new A.lR(r,a,b),!1,q)
A.aC(a,"error",new A.lS(r,a),!1,q)
A.aC(a,"blocked",new A.lT(r),!1,q)
return s},
dq:function dq(a,b){var _=this
_.c=_.b=_.a=null
_.d=a
_.$ti=b},
ri:function ri(a,b){this.a=a
this.b=b},
rj:function rj(a,b){this.a=a
this.b=b},
lM:function lM(a,b,c){this.a=a
this.b=b
this.c=c},
lN:function lN(a,b){this.a=a
this.b=b},
lR:function lR(a,b,c){this.a=a
this.b=b
this.c=c},
lS:function lS(a,b){this.a=a
this.b=b},
lT:function lT(a){this.a=a},
uX(){var s=v.G.navigator
if("storage" in s)return s.storage
return null},
wC(a,b,c){var s=a.read(b,c)
return s},
wD(a,b,c){var s=a.write(b,c)
return s},
Ac(a){var s=t.om
if(!(v.G.Symbol.asyncIterator in a))A.r(A.H("Target object does not implement the async iterable interface",null))
return new A.aL(new A.mU(),new A.eY(a,s),s.h("aL<C.T,v>"))},
mU:function mU(){},
pU:function pU(a){this.a=a},
pV:function pV(a){this.a=a},
pX(a,b){var s=0,r=A.i(t.w),q,p,o
var $async$pX=A.d(function(c,d){if(c===1)return A.e(d,r)
for(;;)switch(s){case 0:p=v.G
o=A
s=3
return A.b(A.aq(p.fetch(new p.URL(a,A.Q(p.location).href),null),t.m),$async$pX)
case 3:q=o.pW(d,null)
s=1
break
case 1:return A.f(q,r)}})
return A.h($async$pX,r)},
pW(a,b){var s=0,r=A.i(t.w),q,p,o,n,m
var $async$pW=A.d(function(c,d){if(c===1)return A.e(d,r)
for(;;)switch(s){case 0:p=new A.ib(A.T(t.S,t.ie))
o=A
n=A
m=A
s=3
return A.b(new A.pU(p).ej(a),$async$pW)
case 3:q=new o.eh(new n.pY(m.Bl(d,p),new A.im(new WeakMap())))
s=1
break
case 1:return A.f(q,r)}})
return A.h($async$pW,r)},
eh:function eh(a){this.a=a},
BP(a){var s=new A.hc(a,new A.L(new A.l($.o,t.D),t.F),a.objectStore("files"),a.objectStore("blocks"))
s.kP(a)
return s},
iu(a,b,c){var s=0,r=A.i(t.cF),q,p,o,n,m,l
var $async$iu=A.d(function(d,e){if(d===1)return A.e(e,r)
for(;;)switch(s){case 0:p=t.N
o=new A.l9(a)
n=A.vb("dart-memory",null)
m=$.kS()
l=new A.cn(o,n,new A.d3(t.p3),A.bp(p),A.T(p,t.S),m,b)
l.r=!1
s=3
return A.b(o.eo(),$async$iu)
case 3:s=4
return A.b(l.cV(),$async$iu)
case 4:q=l
s=1
break
case 1:return A.f(q,r)}})
return A.h($async$iu,r)},
l9:function l9(a){this.a=null
this.b=a},
lc:function lc(a){this.a=a},
lb:function lb(a,b,c){this.a=a
this.b=b
this.c=c},
la:function la(a){this.a=a},
hc:function hc(a,b,c,d){var _=this
_.a=a
_.b=b
_.d=_.c=!1
_.e=c
_.f=d},
rS:function rS(a){this.a=a},
rT:function rT(a){this.a=a},
rU:function rU(a){this.a=a},
rR:function rR(a){this.a=a},
rV:function rV(a,b,c){this.a=a
this.b=b
this.c=c},
rX:function rX(a,b){this.a=a
this.b=b},
rW:function rW(a,b){this.a=a
this.b=b},
ru:function ru(a,b,c){this.a=a
this.b=b
this.c=c},
rv:function rv(a,b){this.a=a
this.b=b},
k8:function k8(a,b){this.a=a
this.b=b},
cn:function cn(a,b,c,d,e,f,g){var _=this
_.d=a
_.e=!1
_.f=null
_.r=!0
_.w=b
_.x=c
_.y=d
_.z=e
_.b=f
_.a=g},
nv:function nv(a,b,c){this.a=a
this.b=b
this.c=c},
nw:function nw(){},
nu:function nu(a,b){this.a=a
this.b=b},
k1:function k1(a,b,c){this.a=a
this.b=b
this.c=c},
rQ:function rQ(a,b){this.a=a
this.b=b},
aD:function aD(){},
ha:function ha(a,b){var _=this
_.w=a
_.d=b
_.c=_.b=_.a=null},
h5:function h5(a,b,c){var _=this
_.w=a
_.x=b
_.d=c
_.c=_.b=_.a=null},
er:function er(a,b,c){var _=this
_.w=a
_.x=b
_.d=c
_.c=_.b=_.a=null},
eL:function eL(a,b,c,d,e){var _=this
_.w=a
_.x=b
_.y=c
_.z=d
_.d=e
_.c=_.b=_.a=null},
x9(a){var s=A.vb("dart-memory",null),r=$.kS()
return new A.e7(s,r,a)},
j5(a,b){var s=0,r=A.i(t.mt),q,p,o,n,m,l,k,j
var $async$j5=A.d(function(c,d){if(c===1)return A.e(d,r)
for(;;)switch(s){case 0:j=A.uX()
if(j==null)throw A.c(A.c6(1))
p=t.m
s=3
return A.b(A.aq(j.getDirectory(),p),$async$j5)
case 3:o=d
n=A.Eg(a),m=J.a0(n.a),n=new A.ek(m,n.b),l=null
case 4:if(!n.l()){s=6
break}s=7
return A.b(A.aq(o.getDirectoryHandle(m.gp(),{create:!0}),p),$async$j5)
case 7:k=d
case 5:l=o,o=k
s=4
break
case 6:q=new A.N(l,o)
s=1
break
case 1:return A.f(q,r)}})
return A.h($async$j5,r)},
j6(a){var s=0,r=A.i(t.m),q
var $async$j6=A.d(function(b,c){if(b===1)return A.e(c,r)
for(;;)switch(s){case 0:s=3
return A.b(A.j5(a,!0),$async$j6)
case 3:q=c.b
s=1
break
case 1:return A.f(q,r)}})
return A.h($async$j6,r)},
ow(a,b){var s=0,r=A.i(t.g_),q,p
var $async$ow=A.d(function(c,d){if(c===1)return A.e(d,r)
for(;;)switch(s){case 0:if(A.uX()==null)throw A.c(A.c6(1))
p=A
s=3
return A.b(A.j6(a),$async$ow)
case 3:q=p.ov(d,!1,b)
s=1
break
case 1:return A.f(q,r)}})
return A.h($async$ow,r)},
ov(a,b,c){var s=0,r=A.i(t.g_),q,p
var $async$ov=A.d(function(d,e){if(d===1)return A.e(e,r)
for(;;)switch(s){case 0:p=A.x9(c)
s=3
return A.b(p.bL(a,!1),$async$ov)
case 3:q=p
s=1
break
case 1:return A.f(q,r)}})
return A.h($async$ov,r)},
dS:function dS(a,b,c){this.c=a
this.a=b
this.b=c},
e7:function e7(a,b,c){var _=this
_.d=null
_.e=a
_.b=b
_.a=c},
ox:function ox(a,b){this.a=a
this.b=b},
kq:function kq(a,b,c){var _=this
_.a=a
_.b=b
_.c=c
_.d=0},
ta:function ta(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=d},
Bl(a,b){var s=A.Q(a.exports.memory)
b.b!==$&&A.yT()
b.b=s
s=new A.pO(s,b,a.exports)
s.kL(a,b)
return s},
vv(a,b){var s,r=A.aU(a.buffer,b,null)
for(s=0;r[s]!==0;)++s
return s},
el(a,b,c){var s=a.buffer
return B.l.aI(A.aU(s,b,c==null?A.vv(a,b):c))},
qp(a,b,c){var s
if(b===0)return null
s=a.buffer
return B.l.aI(A.aU(s,b,c==null?A.vv(a,b):c))},
pO:function pO(a,b,c){var _=this
_.b=a
_.c=b
_.d=c
_.w=_.r=null},
pP:function pP(a){this.a=a},
pQ:function pQ(a){this.a=a},
pR:function pR(a){this.a=a},
pS:function pS(a){this.a=a},
un(){var s=0,r=A.i(t.ja),q,p,o,n,m,l
var $async$un=A.d(function(a,b){if(a===1)return A.e(b,r)
for(;;)switch(s){case 0:m=new v.G.MessageChannel()
l=$.hM()
s=l!=null?3:5
break
case 3:p=A.Dg()
s=6
return A.b(A.ej(l,p,null,null,!1),$async$un)
case 6:o=b
s=4
break
case 5:o=null
p=null
case 4:n=m.port2
q=new A.N({port:m.port1,lockName:p},new A.dN(n,p,o))
s=1
break
case 1:return A.f(q,r)}})
return A.h($async$un,r)},
Dg(){var s,r
for(s=0,r="channel-close-";s<16;++s)r+=A.aQ(97+$.zr().en(26))
return r.charCodeAt(0)==0?r:r},
zQ(a){return new A.f1(a)},
dN:function dN(a,b,c){this.a=a
this.b=b
this.c=c},
o5:function o5(){},
o9:function o9(a){this.a=a},
oa:function oa(a){this.a=a},
o8:function o8(a){this.a=a},
o7:function o7(a){this.a=a},
o6:function o6(a){this.a=a},
ob:function ob(a,b,c){this.a=a
this.b=b
this.c=c},
f1:function f1(a){this.a=a},
AR(a,b){var s=t.H
s=new A.j1(a,b,new A.a9(new A.l($.o,t.ny),t.mE),A.c2(!1,t.e1),new A.jS(A.c2(!1,s)),new A.jS(A.c2(!1,s)))
s.kG(a,b)
return s},
Bn(a,b){var s=t.m,r=A.c2(!1,s),q=new A.l($.o,t.D),p=t.S
s=new A.jF(r,b,a.a,new A.a9(q,t.h),A.T(p,t.br),A.T(p,s))
s.hp(a)
q.J(r.gaG())
return s},
A4(a,b,c,d){var s=A.nL(t.cj)
return new A.mu(d,new A.dZ(s),A.bp(t.jC))},
jS:function jS(a){this.a=null
this.b=a},
j1:function j1(a,b,c,d,e,f){var _=this
_.a=a
_.b=b
_.c=c
_.d=null
_.e=d
_.f=e
_.r=f},
oj:function oj(a){this.a=a},
ok:function ok(a){this.a=a},
of:function of(a){this.a=a},
ol:function ol(a){this.a=a},
om:function om(a){this.a=a},
on:function on(a){this.a=a},
oh:function oh(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=d},
og:function og(a,b,c){this.a=a
this.b=b
this.c=c},
oi:function oi(a,b,c){this.a=a
this.b=b
this.c=c},
jF:function jF(a,b,c,d,e,f){var _=this
_.w=a
_.x=b
_.a=c
_.b=d
_.d=_.c=null
_.e=0
_.f=e
_.r=f},
mu:function mu(a,b,c){this.d=a
this.e=b
this.z=c},
mv:function mv(){},
ia:function ia(a){this.a=a},
m4:function m4(a,b){this.c=a
this.a=b},
cB:function cB(){},
rm:function rm(){},
ip(a,b,c){var s=0,r=A.i(t.eZ),q,p,o
var $async$ip=A.d(function(d,e){if(d===1)return A.e(e,r)
for(;;)switch(s){case 0:s=3
return A.b(A.j6(a),$async$ip)
case 3:p=e
o=A.x9(c)
s=b?4:5
break
case 4:s=6
return A.b(o.bL(p,!0),$async$ip)
case 6:case 5:q=new A.io(o,p,b)
s=1
break
case 1:return A.f(q,r)}})
return A.h($async$ip,r)},
io:function io(a,b,c){this.a=a
this.b=b
this.c=c},
n7:function n7(a,b,c){var _=this
_.a=a
_.b=b
_.c=c
_.d=0},
ej(a,b,c,d,e){var s,r,q={},p=new A.l($.o,t.fV),o=new A.L(p,t.l6)
q.a=null
s={steal:e}
if(c!=null)s.signal=c
r=t.X
A.ir(A.aq(a.request(b,s,A.bz(new A.q6(q,o))),r),new A.q7(q,d,o),r,t.K)
return p},
q6:function q6(a,b){this.a=a
this.b=b},
q7:function q7(a,b,c){this.a=a
this.b=b
this.c=c},
bV:function bV(a){this.a=a},
ic:function ic(a,b,c,d,e){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e
_.r=_.f=null},
mI:function mI(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=d},
mH:function mH(a,b){this.a=a
this.b=b},
mJ:function mJ(a){this.a=a},
dZ:function dZ(a){this.a=!1
this.b=a},
nY:function nY(a,b){this.a=a
this.b=b},
nX:function nX(a,b,c,d,e){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e},
nW:function nW(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=d},
zW(a){var s,r,q,p,o=A.u([],t.kC),n=t.c.a(a.a),m=t.k.b(n)?n:new A.ae(n,A.a5(n).h("ae<1,j>"))
for(s=J.aa(m),r=0;r<s.gk(m)/2;++r){q=r*2
o.push(new A.N(A.mS(B.bw,s.i(m,q)),s.i(m,q+1)))}s=A.aX(a.b)
q=A.aX(a.c)
p=A.aX(a.d)
return new A.cW(o,s,q,A.aX(a.g),p)},
cW:function cW(a,b,c,d,e){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e},
AU(a){var s
if(J.A(a.t,"errorResponse")){s=A.A7(a)
if(s!=null&&s instanceof A.bm)return s
else return new A.d8(a.e,s)}else return new A.d8("Did not respond with expected type, got "+A.q(a),null)},
A7(a){var s=a.s
switch(s==null?null:A.O(s)){case 0:s=A.A8(t.c.a(a.r))
break
case 1:s=B.B
break
default:s=null
break}return s},
A8(a){var s,r,q,p,o=null,n=a.length>=8,m=o,l=o,k=o,j=o,i=o,h=o,g=o
if(n){s=a[0]
m=a[1]
l=a[2]
k=a[3]
j=a[4]
i=a[5]
h=a[6]
g=a[7]}else s=o
if(!n)throw A.c(A.z("Pattern matching error"))
n=new A.mT()
l=A.O(A.by(l))
A.ak(s)
r=n.$1(m)
q=n.$1(j)
if(i!=null&&h!=null){t.c.a(i)
t.a.a(h)
p=new A.cl(i,h,A.aU(h,0,o))}else p=o
n=n.$1(k)
A.y7(g)
return new A.dc(s,r,l,g==null?o:A.O(g),n,q,p)},
A9(a){var s,r,q,p,o,n,m=null,l=a.r
A:{if(l==null){s=m
break A}s=A.vr(l)
break A}r=a.b
if(r==null)r=m
q=a.e
if(q==null)q=m
p=a.f
if(p==null)p=m
o=s==null
n=o?m:s.a
s=o?m:s.b
o=a.d
if(o==null)o=m
return[a.a,r,a.c,q,p,n,s,o]},
AV(a5,a6){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0=null,a1=v.G,a2=new a1.Array(),a3=new a1.ArrayBuffer(512),a4=new A.n7(a3,512,"transfer" in a3)
a6.iI(a5)
for(s=a5.a,r=s.c,q=s.b,p=r.d,r=r.b,o=0,n=!0;A.AP(a5);){if(n){o=p.sqlite3_column_count(q)
n=!1}m=a4.d
l=a4.d=m+o
if(l>a4.b)a4.lB(l)
l=new a1.DataView(a4.a,m,o)
k=new a1.Array(o)
for(j=0;j<o;++j){switch(p.sqlite3_column_type(q,j)){case 1:i=p.sqlite3_column_int64(q,j)
h=a1.Number(i)
if(a1.Number.isSafeInteger(h)){i=h
g=B.U}else g=B.V
break
case 2:i=p.sqlite3_column_double(q,j)
g=B.W
break
case 3:f=p.sqlite3_column_text(q,j)
e=p.sqlite3_column_bytes(q,j)
d=r.buffer
f=new Uint8Array(d,f,e)
c=new A.cI(!1).cQ(f,0,a0,!0)
i=c
g=B.X
break
case 4:f=p.sqlite3_column_bytes(q,j)
b=new Uint8Array(f)
e=p.sqlite3_column_bytes(q,j)
A.aI(0,e,f)
s.km(j,b,0,e)
i=b
g=B.Y
break
case 5:default:i=a0
g=B.Z}k[j]=i
l.setUint8(j,g.a)}a2.push(k)}a=new a1.Array(o)
for(j=0;j<o;++j){a1=p.sqlite3_column_name(q,j)
s=r.buffer
l=A.vv(r,a1)
a1=new Uint8Array(s,a1,l)
a[j]=new A.cI(!1).cQ(a1,0,a0,!0)}return A.yL(!1,a,0,0,a2,a0,a4.oG(0))},
AW(a){var s,r,q,p,o,n,m,l,k,j,i,h=a.c
if(h!=null){s=t.k.b(h)?h:new A.ae(h,A.a5(h).h("ae<1,j>"))
s=J.dI(s,new A.or(),t.N)
r=A.an(s,s.$ti.h("X.E"))
s=a.n
if(s!=null){s=t.fi.b(s)?s:new A.ae(s,A.a5(s).h("ae<1,j?>"))
s=J.dI(s,new A.os(),t.T)
A.an(s,s.$ti.h("X.E"))}s=a.v
q=s==null?null:A.aU(s,0,null)
p=A.u([],t.dO)
s=a.r
s.toString
if(!t.mu.b(s))s=new A.ae(s,A.a5(s).h("ae<1,w<k?>>"))
s=J.a0(s)
o=q!=null
n=0
while(s.l()){m=s.gp()
l=[]
m=B.c.gA(m)
while(m.l()){k=m.gp()
if(o){j=q[n]
i=j>=8?B.w:B.I[j]}else i=B.w
l.push(i.iV(k));++n}p.push(l)}s=new A.bF(p,r,B.by)
s.l_()
return s}else return null},
E8(a){if(a==="sharedCompatibilityCheck"||a==="dedicatedCompatibilityCheck"||a==="dedicatedInSharedCompatibilityCheck")return!0
else return!1},
mT:function mT(){},
or:function or(){},
os:function os(){},
yL(a,b,c,d,e,f,g){return{c:b,n:f,v:g,r:e,x:a,y:c,i:d,t:"rowsResponse"}},
dE(a){var s,r,q,p,o=v.G,n=new o.Array()
switch(a.t){case"connect":n.push(a.r.port)
break
case"fileSystemAccess":s=a.b
if(s!=null)n.push(s)
break
case"runQuery":n.push(a.v)
break
case"simpleSuccessResponse":r=a.r
if(r!=null){o=o.ArrayBuffer
o=r instanceof o
q=r}else{q=null
o=!1}if(o)n.push(q)
break
case"endpointResponse":n.push(a.r.port)
break
case"rowsResponse":p=a.v
if(p!=null)n.push(p)
break}return n},
DQ(a,b,c,d,e){switch(a.t){case"abort":return b.$1(a)
case"notifyUpdate":case"notifyCommit":case"notifyRollback":return c.$1(a)
case"simpleSuccessResponse":case"endpointResponse":case"rowsResponse":case"errorResponse":return e.$1(a)
default:return d.$1(a)}},
fw:function fw(a,b){this.a=a
this.b=b},
oq:function oq(){},
Ad(a){var s,r
for(s=0;s<5;++s){r=B.br[s]
if(r.c===a)return r}throw A.c(A.H("Unknown FS implementation: "+a,null))},
Bb(a){var s,r,q,p,o,n,m,l,k,j=null
A:{if(a==null){s=j
r=B.Z
break A}q=A.hG(a)
p=q?a:j
if(q){s=p
r=B.U
break A}q=a instanceof A.az
if(q)o=a
else o=j
if(q){s=v.G.BigInt(o.j(0))
r=B.V
break A}q=typeof a=="number"
n=q?a:j
if(q){s=n
r=B.W
break A}q=typeof a=="string"
m=q?a:j
if(q){s=m
r=B.X
break A}q=t.p.b(a)
l=q?a:j
if(q){s=l
r=B.Y
break A}q=A.kJ(a)
k=q?a:j
if(q){s=k
r=B.aD
break A}throw A.c(A.H("Unsupported value: "+A.q(a),j))}return new A.N(r,s)},
vr(a){var s,r,q,p,o,n
if(a instanceof A.cl)return new A.N(a.a,a.b)
s=[]
r=J.aa(a)
q=r.gk(a)
p=new Uint8Array(q)
for(o=0;o<r.gk(a);++o){n=A.Bb(r.i(a,o))
p[o]=n.a.a
s.push(n.b)}return new A.N(s,t.a.a(B.e.gau(p)))},
cm:function cm(a,b,c){this.c=a
this.a=b
this.b=c},
bu:function bu(a,b){this.a=a
this.b=b},
cl:function cl(a,b,c){this.a=a
this.b=b
this.c=c},
kM(){var s=0,r=A.i(t.y),q,p=2,o=[],n=[],m,l,k,j,i,h
var $async$kM=A.d(function(a,b){if(a===1){o.push(b)
s=p}for(;;)switch(s){case 0:i=v.G
if(!("indexedDB" in i)||!("FileReader" in i)){q=!1
s=1
break}m=A.Q(i.indexedDB)
i=$.hM()
i=i==null?null:A.ej(i,"drift_mock_db",null,null,!1)
s=3
return A.b(t.fP.b(i)?i:A.bL(i,t.b3),$async$kM)
case 3:l=b
p=5
s=8
return A.b(A.zY(m.open("drift_mock_db"),t.m),$async$kM)
case 8:k=b
k.close()
m.deleteDatabase("drift_mock_db")
n.push(7)
s=6
break
case 5:p=4
h=o.pop()
q=!1
n=[1]
s=6
break
n.push(7)
s=6
break
case 4:n=[2]
case 6:p=2
i=l
if(i!=null)i.a.L()
s=n.pop()
break
case 7:q=!0
s=1
break
case 1:return A.f(q,r)
case 2:return A.e(o.at(-1),r)}})
return A.h($async$kM,r)},
ul(a){return A.DH(a)},
DH(a){var s=0,r=A.i(t.y),q,p=2,o=[],n,m,l,k,j,i
var $async$ul=A.d(function(b,c){if(b===1){o.push(c)
s=p}for(;;)switch(s){case 0:j={}
j.a=null
p=4
n=A.Q(v.G.indexedDB)
m=n.open(a,1)
m.onupgradeneeded=A.bz(new A.um(j,m))
s=7
return A.b(A.zX(m,t.m),$async$ul)
case 7:l=c
if(j.a==null)j.a=!0
l.close()
p=2
s=6
break
case 4:p=3
i=o.pop()
s=6
break
case 3:s=2
break
case 6:j=j.a
q=j===!0
s=1
break
case 1:return A.f(q,r)
case 2:return A.e(o.at(-1),r)}})
return A.h($async$ul,r)},
eV(){var s=0,r=A.i(t.k),q,p=2,o=[],n=[],m,l,k,j,i,h,g
var $async$eV=A.d(function(a,b){if(a===1){o.push(b)
s=p}for(;;)switch(s){case 0:h=A.uX()
if(h==null){q=B.J
s=1
break}j=t.m
s=3
return A.b(A.aq(h.getDirectory(),j),$async$eV)
case 3:m=b
p=5
s=8
return A.b(A.aq(m.getDirectoryHandle("drift_db",{create:!1}),j),$async$eV)
case 8:m=b
p=2
s=7
break
case 5:p=4
g=o.pop()
q=B.J
s=1
break
s=7
break
case 4:s=2
break
case 7:l=A.u([],t.s)
j=new A.bO(A.bA(A.Ac(m),"stream",t.K))
p=9
case 12:s=14
return A.b(j.l(),$async$eV)
case 14:if(!b){s=13
break}k=j.gp()
if(J.A(k.kind,"directory"))J.hN(l,k.name)
s=12
break
case 13:n.push(11)
s=10
break
case 9:n=[2]
case 10:p=2
s=15
return A.b(j.u(),$async$eV)
case 15:s=n.pop()
break
case 11:q=l
s=1
break
case 1:return A.f(q,r)
case 2:return A.e(o.at(-1),r)}})
return A.h($async$eV,r)},
zX(a,b){var s=new A.l($.o,b.h("l<0>")),r=new A.L(s,b.h("L<0>")),q=t.m
A.aC(a,"success",new A.lK(r,a,b),!1,q)
A.aC(a,"error",new A.lL(r,a),!1,q)
return s},
zY(a,b){var s=new A.l($.o,b.h("l<0>")),r=new A.L(s,b.h("L<0>")),q=t.m
A.aC(a,"success",new A.lO(r,a,b),!1,q)
A.aC(a,"error",new A.lP(r,a),!1,q)
A.aC(a,"blocked",new A.lQ(r,a),!1,q)
return s},
um:function um(a,b){this.a=a
this.b=b},
lK:function lK(a,b,c){this.a=a
this.b=b
this.c=c},
lL:function lL(a,b){this.a=a
this.b=b},
lO:function lO(a,b,c){this.a=a
this.b=b
this.c=c},
lP:function lP(a,b){this.a=a
this.b=b},
lQ:function lQ(a,b){this.a=a
this.b=b},
o4:function o4(a,b){this.a=a
this.b=b},
fg:function fg(a,b){this.a=a
this.b=b},
cy:function cy(a,b){this.a=a
this.b=b},
d8:function d8(a,b){this.a=a
this.b=b},
bm:function bm(a,b){this.a=a
this.b=b},
rn:function rn(a){this.a=a},
tK:function tK(){},
rl:function rl(a){this.a=a},
CL(a){var s=a.gnZ()
return new A.aL(new A.tZ(),s,A.p(s).h("aL<C.T,v>"))},
xz(a,b){var s=A.u([],t.kG),r=b==null?a.b:b
return new A.ep(a,r,new A.hu(),new A.hu(),new A.hu(),s)},
BG(a,b,c){var s=t.S
s=new A.eo(c,A.u([],t.ba),a.a,new A.a9(new A.l($.o,t.D),t.h),A.T(s,t.br),A.T(s,t.m))
s.hp(a)
s.kO(a,b,c)
return s},
ye(a){var s
switch(a.a){case 0:s="/database"
break
case 1:s="/database-journal"
break
default:s=null}return s},
tZ:function tZ(){},
hu:function hu(){this.a=null},
ep:function ep(a,b,c,d,e,f){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e
_.f=null
_.r=1
_.w=f},
rd:function rd(a){this.a=a},
rh:function rh(a,b){this.a=a
this.b=b},
re:function re(a,b){this.a=a
this.b=b},
rf:function rf(a){this.a=a},
rg:function rg(a,b){this.a=a
this.b=b},
eo:function eo(a,b,c,d,e,f){var _=this
_.w=a
_.x=b
_.a=c
_.b=d
_.d=_.c=null
_.e=0
_.f=e
_.r=f},
r1:function r1(a){this.a=a},
r4:function r4(a,b,c){this.a=a
this.b=b
this.c=c},
r7:function r7(a,b){this.a=a
this.b=b},
ra:function ra(a,b,c){this.a=a
this.b=b
this.c=c},
r3:function r3(a,b){this.a=a
this.b=b},
r2:function r2(a,b){this.a=a
this.b=b},
r9:function r9(a,b){this.a=a
this.b=b},
r8:function r8(a,b){this.a=a
this.b=b},
rc:function rc(a,b){this.a=a
this.b=b},
rb:function rb(a,b){this.a=a
this.b=b},
r5:function r5(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=d},
r6:function r6(a,b){this.a=a
this.b=b},
r0:function r0(a){this.a=a},
id:function id(a,b,c,d,e,f,g){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e
_.f=f
_.r=g
_.w=1
_.Q=_.z=_.y=_.x=null},
mM:function mM(a){this.a=a},
mL:function mL(a){this.a=a},
mK:function mK(a,b){this.a=a
this.b=b},
ql:function ql(a,b,c,d,e,f){var _=this
_.a=a
_.b=b
_.c=c
_.d=0
_.e=d
_.f=0
_.w=_.r=null
_.x=e
_.y=f
_.Q=$},
qm:function qm(a,b){this.a=a
this.b=b},
qn:function qn(a,b){this.a=a
this.b=b},
qo:function qo(a){this.a=a},
C7(){return new A.tf(A.jY(new A.tg(),t.z))},
iH:function iH(a){this.a=a},
tf:function tf(a){this.a=null
this.b=a},
tg:function tg(){},
tk:function tk(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=d},
th:function th(a,b){this.a=a
this.b=b},
ti:function ti(a){this.a=a},
tl:function tl(a,b){this.a=a
this.b=b},
tj:function tj(a){this.a=a},
jf:function jf(){},
jg:function jg(){},
oD:function oD(a,b,c){this.a=a
this.b=b
this.c=c},
bB:function bB(a){this.a=a},
ot(a,b,c){return A.AY(a,b,c,c)},
AY(a,b,c,d){var s=0,r=A.i(d),q,p=2,o=[],n=[],m,l
var $async$ot=A.d(function(e,f){if(e===1){o.push(f)
s=p}for(;;)switch(s){case 0:l=new A.fE(a)
p=3
s=6
return A.b(b.$1(l),$async$ot)
case 6:m=f
q=m
n=[1]
s=4
break
n.push(5)
s=4
break
case 3:n=[2]
case 4:p=2
l.c=!0
s=n.pop()
break
case 5:case 1:return A.f(q,r)
case 2:return A.e(o.at(-1),r)}})
return A.h($async$ot,r)},
AZ(a){var s
A:{if(0===a){s=B.bB
break A}s=""+a
s=new A.hq("SAVEPOINT s"+s,"RELEASE s"+s,"ROLLBACK TO s"+s)
break A}return s},
fG(a,b,c){return A.B_(a,b,c,c)},
B_(a,b,c,d){var s=0,r=A.i(d),q,p=2,o=[],n=[],m,l
var $async$fG=A.d(function(e,f){if(e===1){o.push(f)
s=p}for(;;)switch(s){case 0:l=new A.fF(0,a)
p=3
s=6
return A.b(b.$1(l),$async$fG)
case 6:m=f
s=7
return A.b(a.e7(),$async$fG)
case 7:q=m
n=[1]
s=4
break
n.push(5)
s=4
break
case 3:n=[2]
case 4:p=2
l.c=!0
s=n.pop()
break
case 5:case 1:return A.f(q,r)
case 2:return A.e(o.at(-1),r)}})
return A.h($async$fG,r)},
jv:function jv(){},
fE:function fE(a){this.a=a
this.c=this.b=!1},
fF:function fF(a,b){var _=this
_.d=a
_.a=b
_.c=_.b=!1},
je:function je(){},
oB:function oB(a,b){this.a=a
this.b=b},
oC:function oC(a,b){this.a=a
this.b=b},
Bc(a){return new A.I(a)},
Be(a,b,c){return A.Dv(new A.pH(),c,a,!0,b,t.d)},
Bd(a){var s,r=A.bp(t.N)
for(s=0;s<1;++s)r.q(0,a[s].toLowerCase())
return new A.kr(new A.pG(r))},
Dv(a,b,c,d,e,f){return new A.bx(!1,new A.ub(e,a,c,b,!0,f),f.h("bx<0>"))},
I:function I(a){this.a=a},
pH:function pH(){},
pG:function pG(a){this.a=a},
pF:function pF(a){this.a=a},
ub:function ub(a,b,c,d,e,f){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e
_.f=f},
uc:function uc(a,b){this.a=a
this.b=b},
ud:function ud(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=d},
u7:function u7(a,b,c){this.a=a
this.b=b
this.c=c},
u6:function u6(a,b){this.a=a
this.b=b},
ue:function ue(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=d},
ug:function ug(a,b){this.a=a
this.b=b},
uf:function uf(a,b){this.a=a
this.b=b},
u8:function u8(a){this.a=a},
u9:function u9(a,b,c){this.a=a
this.b=b
this.c=c},
ua:function ua(a,b){this.a=a
this.b=b},
xj(a,b,c,d,e,f){var s
if(a==null)return c.$0()
s=A.Ek(b,d,e)
a.pD(s.a,s.b)
return A.dT(c,f).J(new A.pw(a))},
Ek(a,b,c){var s,r,q,p,o,n,m=t.z
m=A.T(m,m)
m.m(0,"sql",c)
s=[]
for(r=b.length,q=t.j,p=0;p<b.length;b.length===r||(0,A.a6)(b),++p){o=b[p]
A:{if(q.b(o)){n="<blob>"
break A}if(o instanceof A.az){n=o.j(0)
break A}n=o
break A}s.push(n)}m.m(0,"parameters",s)
return new A.N("sqlite_async:"+a+" "+c,m)},
pw:function pw(a){this.a=a},
eT(a,b,c,d){return A.E6(a,b,c,d,d)},
E6(a,b,c,d,e){var s=0,r=A.i(e),q,p=2,o=[],n,m,l,k,j
var $async$eT=A.d(function(f,g){if(f===1){o.push(g)
s=p}for(;;)switch(s){case 0:p=4
s=7
return A.b(a.eI(c?"BEGIN IMMEDIATE":"BEGIN"),$async$eT)
case 7:s=8
return A.b(b.$1(a),$async$eT)
case 8:n=g
s=9
return A.b(a.eI("END TRANSACTION"),$async$eT)
case 9:q=n
s=1
break
p=2
s=6
break
case 4:p=3
k=o.pop()
p=11
s=14
return A.b(a.eI("ROLLBACK"),$async$eT)
case 14:p=3
s=13
break
case 11:p=10
j=o.pop()
s=13
break
case 10:s=3
break
case 13:throw k
s=6
break
case 3:s=2
break
case 6:case 1:return A.f(q,r)
case 2:return A.e(o.at(-1),r)}})
return A.h($async$eT,r)},
xi(a){var s={},r=A.u([],t.jI),q=A.bp(t.N)
s.a=A.u([],t.bO)
return new A.bx(!0,new A.pt(new A.po(s,r,a,new A.pu(q),new A.pr(r,q),new A.ps(q)),new A.pv(s,r)),t.cn)},
pu:function pu(a){this.a=a},
pr:function pr(a,b){this.a=a
this.b=b},
ps:function ps(a){this.a=a},
po:function po(a,b,c,d,e,f){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e
_.f=f},
pp:function pp(a){this.a=a},
pq:function pq(a){this.a=a},
pv:function pv(a,b){this.a=a
this.b=b},
pt:function pt(a,b){this.a=a
this.b=b},
pn:function pn(a,b){this.a=a
this.b=b},
dx:function dx(a,b){this.a=a
this.b=b},
kR(a,b){return A.Ez(a,b,b)},
Ez(a,b,c){var s=0,r=A.i(c),q,p=2,o=[],n,m,l,k,j,i,h
var $async$kR=A.d(function(d,e){if(d===1){o.push(e)
s=p}for(;;)switch(s){case 0:p=4
s=7
return A.b(a.$0(),$async$kR)
case 7:j=e
q=j
s=1
break
p=2
s=6
break
case 4:p=3
h=o.pop()
j=A.E(h)
if(j instanceof A.d8){n=j
m=n.b
l=null
if(m!=null){l=m
throw A.c(l)}if(B.a.V(n.a,"Database is not in a transaction"))throw A.c(A.jh(null,null,0,"Transaction rolled back by earlier statement. Cannot execute.",null,null,null))
if(B.a.V("Remote error: "+n.a,"SqliteException")){k=A.at("SqliteException\\((\\d+)\\)",!0)
j=k.j0(n.a)
j=j==null?null:j.i(0,1)
throw A.c(A.jh(null,null,A.yG(j==null?"0":j),n.a,null,null,null))}throw h}else throw h
s=6
break
case 3:s=2
break
case 6:case 1:return A.f(q,r)
case 2:return A.e(o.at(-1),r)}})
return A.h($async$kR,r)},
CM(a,b,c){return A.ir(a,new A.u_(b),c,t.fN)},
jC:function jC(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=d},
q2:function q2(a,b){this.a=a
this.b=b},
q5:function q5(a,b){this.a=a
this.b=b},
q4:function q4(a,b){this.a=a
this.b=b},
q3:function q3(a,b){this.a=a
this.b=b},
q0:function q0(a,b,c){this.a=a
this.b=b
this.c=c},
q1:function q1(a,b,c){this.a=a
this.b=b
this.c=c},
ce:function ce(a,b,c){var _=this
_.a=a
_.b=b
_.c=c
_.d=!1},
tE:function tE(a,b,c){this.a=a
this.b=b
this.c=c},
tD:function tD(a,b,c){this.a=a
this.b=b
this.c=c},
tC:function tC(a,b,c){this.a=a
this.b=b
this.c=c},
tB:function tB(a,b,c){this.a=a
this.b=b
this.c=c},
u_:function u_(a){this.a=a},
BE(a){var s=a.a,r=A.p(s).h("bU<1,j>")
s=A.an(new A.bU(s,new A.qV(),r),r.h("m.E"))
return{a:0,b:s}},
i1:function i1(a){this.b=a},
lj:function lj(){},
lh:function lh(){},
li:function li(){},
qV:function qV(){},
v6(a,b,c){var s=A.vr(c)
return{rawKind:a.b,rawSql:b,rawParameters:s.a,typeInfo:s.b}},
bR:function bR(a,b){this.a=a
this.b=b},
jw:function jw(a){this.a=0
this.b=a},
pC:function pC(){},
pD:function pD(a,b){this.a=a
this.b=b},
pE:function pE(a,b,c){this.a=a
this.b=b
this.c=c},
q9(a){var s=A.C7()
return new A.q8(s,a)},
q8:function q8(a,b){this.a=a
this.b=b},
qa:function qa(a,b,c){this.a=a
this.b=b
this.c=c},
qc:function qc(a){this.a=a},
qb:function qb(){},
fk:function fk(a){this.a=a},
BH(){return new A.eq()},
l5:function l5(){},
hW:function hW(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=null
_.e=d},
l6:function l6(a){this.a=a},
l7:function l7(a,b){this.a=a
this.b=b},
l8:function l8(a,b,c){this.a=a
this.b=b
this.c=c},
eq:function eq(){this.a=!1
this.b=null},
jn:function jn(a,b,c){this.c=a
this.a=b
this.b=c},
p9:function p9(a,b){var _=this
_.a=a
_.b=b
_.c=0
_.e=_.d=null},
ef:function ef(){},
k2:function k2(){},
bd:function bd(a,b){this.a=a
this.b=b},
aC(a,b,c,d,e){var s
if(c==null)s=null
else{s=A.yw(new A.rs(c),t.m)
s=s==null?null:A.bz(s)}s=new A.ev(a,b,s,!1,e.h("ev<0>"))
s.fs()
return s},
yw(a,b){var s=$.o
if(s===B.f)return a
return s.iK(a,b)},
v7:function v7(a,b){this.a=a
this.$ti=b},
eu:function eu(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.$ti=d},
ev:function ev(a,b,c,d,e){var _=this
_.a=0
_.b=a
_.c=b
_.d=c
_.e=d
_.$ti=e},
rs:function rs(a){this.a=a},
rt:function rt(a){this.a=a},
qd(a){var s=0,r=A.i(t.m1),q,p,o,n,m
var $async$qd=A.d(function(b,c){if(b===1)return A.e(c,r)
for(;;)switch(s){case 0:o=new A.jw(A.T(t.N,t.ao))
s=3
return A.b(A.A4(B.b4,v.G.location.href,B.b1,o.gnS()).fC(new A.N(a.b,a.a)),$async$qd)
case 3:n=c
m=a.c
A:{p=null
if(m!=null){p=A.q9(m)
break A}break A}q=new A.jC(n,p,!1,o.oM(n))
s=1
break
case 1:return A.f(q,r)}})
return A.h($async$qd,r)},
yW(a){return v.mangledGlobalNames[a]},
Ej(a){if(typeof dartPrint=="function"){dartPrint(a)
return}if(typeof console=="object"&&typeof console.log!="undefined"){console.log(a)
return}if(typeof print=="function"){print(a)
return}throw"Unable to print message: "+String(a)},
As(a,b){return b in a},
ve(a,b,c,d,e,f){var s
if(c==null)return a[b]()
else if(d==null)return a[b](c)
else if(e==null)return a[b](c,d)
else{s=a[b](c,d,e)
return s}},
wJ(a,b){return b in a},
DY(a,b,c,d){var s,r,q,p,o,n=A.T(d,c.h("t<0>"))
for(s=c.h("w<0>"),r=0;r<1;++r){q=a[r]
p=b.$1(q)
o=n.i(0,p)
if(o==null){o=A.u([],s)
n.m(0,p,o)
p=o}else p=o
J.hN(p,q)}return n},
wI(a,b){var s,r=A.bp(b)
for(s=a.a,s=new A.b3(s,s.r,s.e);s.l();)r.a7(0,s.d)
return r},
w2(a){var s,r=a.c.a.i(0,"charset")
if(a.a==="application"&&a.b==="json"&&r==null)return B.l
if(r!=null){s=A.wy(r)
if(s==null)s=B.k}else s=B.k
return s},
yV(a){return a},
yU(a){return new A.cQ(a)},
Ey(a,b,c){var s,r,q,p
try{q=c.$0()
return q}catch(p){q=A.E(p)
if(q instanceof A.e8){s=q
throw A.c(A.B2("Invalid "+a+": "+s.a,s.b,s.gdD()))}else if(t.lW.b(q)){r=q
throw A.c(A.ai("Invalid "+a+' "'+b+'": '+r.gjh(),r.gdD(),r.gaa()))}else throw p}},
yC(){var s,r,q,p,o=null
try{o=A.vt()}catch(s){if(t.L.b(A.E(s))){r=$.tX
if(r!=null)return r
throw s}else throw s}if(J.A(o,$.yc)){r=$.tX
r.toString
return r}$.yc=o
if($.wa()===$.hL())r=$.tX=o.dr(".").j(0)
else{q=o.h6()
p=q.length-1
r=$.tX=p===0?q:B.a.t(q,0,p)}return r},
yH(a){var s
if(!(a>=65&&a<=90))s=a>=97&&a<=122
else s=!0
return s},
yD(a,b){var s,r,q=null,p=a.length,o=b+2
if(p<o)return q
if(!A.yH(a.charCodeAt(b)))return q
s=b+1
if(a.charCodeAt(s)!==58){r=b+4
if(p<r)return q
if(B.a.t(a,s,r).toLowerCase()!=="%3a")return q
b=o}s=b+2
if(p===s)return s
if(a.charCodeAt(s)!==47)return q
return b+3},
DV(a){if(B.a.K(a,"ps_data_local__"))return B.a.a1(a,15)
else if(B.a.K(a,"ps_data__"))return B.a.a1(a,9)
else return null},
Aj(a){var s=t.N
return t.f.a(B.h.aI(a.h)).bl(0,s,s)},
E7(a){var s,r,q,p
if(a.gk(0)===0)return!0
s=a.gai(0)
for(r=A.bJ(a,1,null,a.$ti.h("X.E")),q=r.$ti,r=new A.as(r,r.gk(0),q.h("as<X.E>")),q=q.h("X.E");r.l();){p=r.d
if(!J.A(p==null?q.a(p):p,s))return!1}return!0},
El(a,b){var s=B.c.c7(a,null)
if(s<0)throw A.c(A.H(A.q(a)+" contains no null elements.",null))
a[s]=b},
yP(a,b){var s=B.c.c7(a,b)
if(s<0)throw A.c(A.H(A.q(a)+" contains no elements matching "+b.j(0)+".",null))
a[s]=null},
DN(a,b){var s,r,q,p
for(s=new A.bn(a),r=t.V,s=new A.as(s,s.gk(0),r.h("as<y.E>")),r=r.h("y.E"),q=0;s.l();){p=s.d
if((p==null?r.a(p):p)===b)++q}return q},
uq(a,b,c){var s,r,q
if(b.length===0)for(s=0;;){r=B.a.bn(a,"\n",s)
if(r===-1)return a.length-s>=c?s:null
if(r-s>=c)return s
s=r+1}r=B.a.c7(a,b)
while(r!==-1){q=r===0?0:B.a.eh(a,"\n",r-1)+1
if(c===r-q)return q
r=B.a.bn(a,b,r+1)}return null},
w1(a,b,c,d,e,f){var s,r=b.a,q=b.b,p=r.d,o=p.sqlite3_extended_errcode(q),n=p.sqlite3_error_offset(q)
A:{if(n<0){n=null
break A}break A}s=a.a
return new A.dc(A.el(r.b,p.sqlite3_errmsg(q),null),A.el(s.b,s.d.sqlite3_errstr(o),null)+" (code "+A.q(o)+")",c,n,d,e,f)},
w8(a,b,c,d,e){throw A.c(A.w1(a.a,a.b,b,c,d,e))},
wF(a,b){var s,r
for(s=b,r=0;r<16;++r)s+=A.aQ("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ012346789".charCodeAt(a.en(61)))
return s.charCodeAt(0)==0?s:s},
od(a){var s=0,r=A.i(t.lo),q
var $async$od=A.d(function(b,c){if(b===1)return A.e(c,r)
for(;;)switch(s){case 0:s=3
return A.b(A.aq(a.arrayBuffer(),t.a),$async$od)
case 3:q=c
s=1
break
case 1:return A.f(q,r)}})
return A.h($async$od,r)},
wT(a,b,c,d){A.ve(a,"setBigInt64",b,c,!0,null)},
cK(){var s=0,r=A.i(t.kO),q,p=2,o=[],n=[],m,l,k,j,i,h,g,f,e,d,c,b,a
var $async$cK=A.d(function(a0,a1){if(a0===1){o.push(a1)
s=p}for(;;)switch(s){case 0:b=A.uX()
if(b==null){q=B.N
s=1
break}m=null
l=null
k=null
j=null
i=!1
p=4
d=$.hM()
d=d==null?null:A.ej(d,"_drift_feature_detection",null,null,!1)
s=7
return A.b(t.fP.b(d)?d:A.bL(d,t.b3),$async$cK)
case 7:j=a1
d=t.m
s=8
return A.b(A.aq(b.getDirectory(),d),$async$cK)
case 8:m=a1
s=9
return A.b(A.aq(m.getFileHandle("_drift_feature_detection",{create:!0}),d),$async$cK)
case 9:l=a1
s=10
return A.b(A.hJ(l),$async$cK)
case 10:h=a1
g=null
f=null
g=h.a
f=h.b
i=g
k=f
e=A.ve(k,"getSize",null,null,null,null)
s=typeof e==="object"?11:12
break
case 11:s=13
return A.b(A.aq(A.Q(e),t.X),$async$cK)
case 13:q=B.N
n=[1]
s=5
break
case 12:g=i
q=new A.ho(!0,g)
n=[1]
s=5
break
n.push(6)
s=5
break
case 4:p=3
a=o.pop()
q=B.N
n=[1]
s=5
break
n.push(6)
s=5
break
case 3:n=[2]
case 5:p=2
g=j
if(g!=null)g.a.L()
if(k!=null)k.close()
s=m!=null&&l!=null?14:15
break
case 14:s=16
return A.b(A.aq(m.removeEntry("_drift_feature_detection",{recursive:!1}),t.X),$async$cK)
case 16:case 15:s=n.pop()
break
case 6:case 1:return A.f(q,r)
case 2:return A.e(o.at(-1),r)}})
return A.h($async$cK,r)},
hJ(a){return A.Dw(a)},
Dw(a){var s=0,r=A.i(t.mk),q,p=2,o=[],n,m,l,k,j,i
var $async$hJ=A.d(function(b,c){if(b===1){o.push(c)
s=p}for(;;)switch(s){case 0:j=null
p=4
l=t.m
s=7
return A.b(A.aq(a.createSyncAccessHandle({mode:"readwrite-unsafe"}),l),$async$hJ)
case 7:j=c
s=8
return A.b(A.aq(a.createSyncAccessHandle({mode:"readwrite-unsafe"}),l),$async$hJ)
case 8:n=c
n.close()
l=j
q=new A.N(!0,l)
s=1
break
p=2
s=6
break
case 4:p=3
i=o.pop()
l=j
if(l!=null)l.close()
s=9
return A.b(A.aq(a.createSyncAccessHandle(),t.m),$async$hJ)
case 9:m=c
q=new A.N(!1,m)
s=1
break
s=6
break
case 3:s=2
break
case 6:case 1:return A.f(q,r)
case 2:return A.e(o.at(-1),r)}})
return A.h($async$hJ,r)}},B={}
var w=[A,J,B]
var $={}
A.vg.prototype={}
J.W.prototype={
D(a,b){return a===b},
gv(a){return A.e3(a)},
j(a){return"Instance of '"+A.iY(a)+"'"},
ga4(a){return A.bj(A.vV(this))}}
J.ix.prototype={
j(a){return String(a)},
gv(a){return a?519018:218159},
ga4(a){return A.bj(t.y)},
$ia_:1,
$iG:1}
J.dV.prototype={
D(a,b){return null==b},
j(a){return"null"},
gv(a){return 0},
$ia_:1,
$iD:1}
J.ag.prototype={$iv:1}
J.cp.prototype={
gv(a){return 0},
ga4(a){return B.bM},
j(a){return String(a)}}
J.iW.prototype={}
J.dg.prototype={}
J.b_.prototype={
j(a){var s=a[$.z_()]
if(s==null)s=a[$.dH()]
if(s==null)return this.kt(a)
return"JavaScript function for "+J.bb(s)}}
J.aN.prototype={
gv(a){return 0},
j(a){return String(a)}}
J.d_.prototype={
gv(a){return 0},
j(a){return String(a)}}
J.w.prototype={
e6(a,b){return new A.ae(a,A.a5(a).h("@<1>").I(b).h("ae<1,2>"))},
q(a,b){a.$flags&1&&A.B(a,29)
a.push(b)},
es(a,b){var s
a.$flags&1&&A.B(a,"removeAt",1)
s=a.length
if(b>=s)throw A.c(A.oc(b,null))
return a.splice(b,1)[0]},
o0(a,b,c){var s
a.$flags&1&&A.B(a,"insert",2)
s=a.length
if(b>s)throw A.c(A.oc(b,null))
a.splice(b,0,c)},
fR(a,b,c){var s,r
a.$flags&1&&A.B(a,"insertAll",2)
A.x5(b,0,a.length,"index")
if(!t.O.b(c))c=J.zK(c)
s=J.aM(c)
a.length=a.length+s
r=b+s
this.Y(a,r,a.length,a,b)
this.af(a,b,r,c)},
jt(a){a.$flags&1&&A.B(a,"removeLast",1)
if(a.length===0)throw A.c(A.kO(a,-1))
return a.pop()},
H(a,b){var s
a.$flags&1&&A.B(a,"remove",1)
for(s=0;s<a.length;++s)if(J.A(a[s],b)){a.splice(s,1)
return!0}return!1},
m2(a,b,c){var s,r,q,p=[],o=a.length
for(s=0;s<o;++s){r=a[s]
if(!b.$1(r))p.push(r)
if(a.length!==o)throw A.c(A.am(a))}q=p.length
if(q===o)return
this.sk(a,q)
for(s=0;s<p.length;++s)a[s]=p[s]},
a7(a,b){var s
a.$flags&1&&A.B(a,"addAll",2)
if(Array.isArray(b)){this.kW(a,b)
return}for(s=J.a0(b);s.l();)a.push(s.gp())},
kW(a,b){var s,r=b.length
if(r===0)return
if(a===b)throw A.c(A.am(a))
for(s=0;s<r;++s)a.push(b[s])},
aF(a){a.$flags&1&&A.B(a,"clear","clear")
a.length=0},
ba(a,b,c){return new A.a8(a,b,A.a5(a).h("@<1>").I(c).h("a8<1,2>"))},
bp(a,b){var s,r=A.b4(a.length,"",!1,t.N)
for(s=0;s<a.length;++s)r[s]=A.q(a[s])
return r.join(b)},
bN(a,b){return A.bJ(a,0,A.bA(b,"count",t.S),A.a5(a).c)},
aT(a,b){return A.bJ(a,b,null,A.a5(a).c)},
j1(a,b){var s,r,q=a.length
for(s=0;s<q;++s){r=a[s]
if(b.$1(r))return r
if(a.length!==q)throw A.c(A.am(a))}throw A.c(A.bW())},
W(a,b){return a[b]},
gai(a){if(a.length>0)return a[0]
throw A.c(A.bW())},
gaP(a){var s=a.length
if(s>0)return a[s-1]
throw A.c(A.bW())},
Y(a,b,c,d,e){var s,r,q,p,o
a.$flags&2&&A.B(a,5)
A.aI(b,c,a.length)
s=c-b
if(s===0)return
A.aH(e,"skipCount")
if(t.j.b(d)){r=d
q=e}else{r=J.kZ(d,e).ca(0,!1)
q=0}p=J.aa(r)
if(q+s>p.gk(r))throw A.c(A.wH())
if(q<b)for(o=s-1;o>=0;--o)a[b+o]=p.i(r,q+o)
else for(o=0;o<s;++o)a[b+o]=p.i(r,q+o)},
af(a,b,c,d){return this.Y(a,b,c,d,0)},
cM(a,b){var s,r,q,p,o
a.$flags&2&&A.B(a,"sort")
s=a.length
if(s<2)return
if(b==null)b=J.CU()
if(s===2){r=a[0]
q=a[1]
if(b.$2(r,q)>0){a[0]=q
a[1]=r}return}p=0
if(A.a5(a).c.b(null))for(o=0;o<a.length;++o)if(a[o]===void 0){a[o]=null;++p}a.sort(A.dD(b,2))
if(p>0)this.m3(a,p)},
kl(a){return this.cM(a,null)},
m3(a,b){var s,r=a.length
for(;s=r-1,r>0;r=s)if(a[s]===null){a[s]=void 0;--b
if(b===0)break}},
c7(a,b){var s,r=a.length
if(0>=r)return-1
for(s=0;s<r;++s)if(J.A(a[s],b))return s
return-1},
cw(a,b){var s,r=a.length,q=r-1
if(q<0)return-1
q<r
for(s=q;s>=0;--s)if(J.A(a[s],b))return s
return-1},
V(a,b){var s
for(s=0;s<a.length;++s)if(J.A(a[s],b))return!0
return!1},
gE(a){return a.length===0},
gaO(a){return a.length!==0},
j(a){return A.nE(a,"[","]")},
ca(a,b){var s=A.u(a.slice(0),A.a5(a))
return s},
jy(a){return this.ca(a,!0)},
gA(a){return new J.dJ(a,a.length,A.a5(a).h("dJ<1>"))},
gv(a){return A.e3(a)},
gk(a){return a.length},
sk(a,b){a.$flags&1&&A.B(a,"set length","change the length of")
if(b<0)throw A.c(A.ab(b,0,null,"newLength",null))
if(b>a.length)A.a5(a).c.a(null)
a.length=b},
i(a,b){if(!(b>=0&&b<a.length))throw A.c(A.kO(a,b))
return a[b]},
m(a,b,c){a.$flags&2&&A.B(a)
if(!(b>=0&&b<a.length))throw A.c(A.kO(a,b))
a[b]=c},
o_(a,b){var s
if(0>=a.length)return-1
for(s=0;s<a.length;++s)if(b.$1(a[s]))return s
return-1},
ga4(a){return A.bj(A.a5(a))},
$iaE:1,
$ix:1,
$im:1,
$it:1}
J.iw.prototype={
oK(a){var s,r,q
if(!Array.isArray(a))return null
s=a.$flags|0
if((s&4)!==0)r="const, "
else if((s&2)!==0)r="unmodifiable, "
else r=(s&1)!==0?"fixed, ":""
q="Instance of '"+A.iY(a)+"'"
if(r==="")return q
return q+" ("+r+"length: "+a.length+")"}}
J.nF.prototype={}
J.dJ.prototype={
gp(){var s=this.d
return s==null?this.$ti.c.a(s):s},
l(){var s,r=this,q=r.a,p=q.length
if(r.b!==p)throw A.c(A.a6(q))
s=r.c
if(s>=p){r.d=null
return!1}r.d=q[s]
r.c=s+1
return!0}}
J.dW.prototype={
a0(a,b){var s
if(a<b)return-1
else if(a>b)return 1
else if(a===b){if(a===0){s=this.gfU(b)
if(this.gfU(a)===s)return 0
if(this.gfU(a))return-1
return 1}return 0}else if(isNaN(a)){if(isNaN(b))return 0
return 1}else return-1},
gfU(a){return a===0?1/a<0:a<0},
mM(a){var s,r
if(a>=0){if(a<=2147483647){s=a|0
return a===s?s:s+1}}else if(a>=-2147483648)return a|0
r=Math.ceil(a)
if(isFinite(r))return r
throw A.c(A.R(""+a+".ceil()"))},
mN(a,b,c){if(B.b.a0(b,c)>0)throw A.c(A.dC(b))
if(this.a0(a,b)<0)return b
if(this.a0(a,c)>0)return c
return a},
oI(a,b){var s,r,q,p
if(b<2||b>36)throw A.c(A.ab(b,2,36,"radix",null))
s=a.toString(b)
if(s.charCodeAt(s.length-1)!==41)return s
r=/^([\da-z]+)(?:\.([\da-z]+))?\(e\+(\d+)\)$/.exec(s)
if(r==null)A.r(A.R("Unexpected toString result: "+s))
s=r[1]
q=+r[3]
p=r[2]
if(p!=null){s+=p
q-=p.length}return s+B.a.aL("0",q)},
j(a){if(a===0&&1/a<0)return"-0.0"
else return""+a},
gv(a){var s,r,q,p,o=a|0
if(a===o)return o&536870911
s=Math.abs(a)
r=Math.log(s)/0.6931471805599453|0
q=Math.pow(2,r)
p=s<1?s/q:q/s
return((p*9007199254740992|0)+(p*3542243181176521|0))*599197+r*1259&536870911},
dw(a,b){return a+b},
aS(a,b){var s=a%b
if(s===0)return 0
if(s>0)return s
return s+b},
kE(a,b){if((a|0)===a)if(b>=1||b<-1)return a/b|0
return this.ip(a,b)},
R(a,b){return(a|0)===a?a/b|0:this.ip(a,b)},
ip(a,b){var s=a/b
if(s>=-2147483648&&s<=2147483647)return s|0
if(s>0){if(s!==1/0)return Math.floor(s)}else if(s>-1/0)return Math.ceil(s)
throw A.c(A.R("Result of truncating division is "+A.q(s)+": "+A.q(a)+" ~/ "+b))},
cK(a,b){if(b<0)throw A.c(A.dC(b))
return b>31?0:a<<b>>>0},
cL(a,b){var s
if(b<0)throw A.c(A.dC(b))
if(a>0)s=this.fp(a,b)
else{s=b>31?31:b
s=a>>s>>>0}return s},
Z(a,b){var s
if(a>0)s=this.fp(a,b)
else{s=b>31?31:b
s=a>>s>>>0}return s},
mh(a,b){if(0>b)throw A.c(A.dC(b))
return this.fp(a,b)},
fp(a,b){return b>31?0:a>>>b},
kd(a,b){return a>b},
ga4(a){return A.bj(t.q)},
$ia7:1,
$iY:1}
J.fn.prototype={
giL(a){var s,r=a<0?-a-1:a,q=r
for(s=32;q>=4294967296;){q=this.R(q,4294967296)
s+=32}return s-Math.clz32(q)},
ga4(a){return A.bj(t.S)},
$ia_:1,
$ia:1}
J.iy.prototype={
ga4(a){return A.bj(t.i)},
$ia_:1}
J.co.prototype={
fA(a,b,c){var s=b.length
if(c>s)throw A.c(A.ab(c,0,s,null,null))
return new A.kt(b,a,c)},
e2(a,b){return this.fA(a,b,0)},
cA(a,b,c){var s,r,q=null
if(c<0||c>b.length)throw A.c(A.ab(c,0,b.length,q,q))
s=a.length
if(c+s>b.length)return q
for(r=0;r<s;++r)if(b.charCodeAt(c+r)!==a.charCodeAt(r))return q
return new A.fL(c,a)},
bF(a,b){var s=b.length,r=a.length
if(s>r)return!1
return b===this.a1(a,r-s)},
dE(a,b){var s=A.u(a.split(b),t.s)
return s},
c9(a,b,c,d){var s=A.aI(b,c,a.length)
return A.yS(a,b,s,d)},
S(a,b,c){var s
if(c<0||c>a.length)throw A.c(A.ab(c,0,a.length,null,null))
s=c+b.length
if(s>a.length)return!1
return b===a.substring(c,s)},
K(a,b){return this.S(a,b,0)},
t(a,b,c){return a.substring(b,A.aI(b,c,a.length))},
a1(a,b){return this.t(a,b,null)},
aL(a,b){var s,r
if(0>=b)return""
if(b===1||a.length===0)return a
if(b!==b>>>0)throw A.c(B.aY)
for(s=a,r="";;){if((b&1)===1)r=s+r
b=b>>>1
if(b===0)break
s+=s}return r},
oq(a,b,c){var s=b-a.length
if(s<=0)return a
return this.aL(c,s)+a},
or(a,b){var s=b-a.length
if(s<=0)return a
return a+this.aL(" ",s)},
bn(a,b,c){var s
if(c<0||c>a.length)throw A.c(A.ab(c,0,a.length,null,null))
s=a.indexOf(b,c)
return s},
c7(a,b){return this.bn(a,b,0)},
eh(a,b,c){var s,r
if(c==null)c=a.length
else if(c<0||c>a.length)throw A.c(A.ab(c,0,a.length,null,null))
s=b.length
r=a.length
if(c+s>r)c=r-s
return a.lastIndexOf(b,c)},
cw(a,b){return this.eh(a,b,null)},
V(a,b){return A.Es(a,b,0)},
a0(a,b){var s
if(a===b)s=0
else s=a<b?-1:1
return s},
j(a){return a},
gv(a){var s,r,q
for(s=a.length,r=0,q=0;q<s;++q){r=r+a.charCodeAt(q)&536870911
r=r+((r&524287)<<10)&536870911
r^=r>>6}r=r+((r&67108863)<<3)&536870911
r^=r>>11
return r+((r&16383)<<15)&536870911},
ga4(a){return A.bj(t.N)},
gk(a){return a.length},
i(a,b){if(!(b>=0&&b<a.length))throw A.c(A.kO(a,b))
return a[b]},
$iaE:1,
$ia_:1,
$ia7:1,
$ij:1}
A.cT.prototype={
gaw(){return this.a.gaw()},
B(a,b,c,d){var s=this.a.bq(null,b,c),r=new A.dK(s,$.o,this.$ti.h("dK<1,2>"))
s.bt(r.gkT())
r.bt(a)
r.dk(d)
return r},
O(a){return this.B(a,null,null,null)},
az(a,b,c){return this.B(a,null,b,c)},
bq(a,b,c){return this.B(a,b,c,null)}}
A.dK.prototype={
u(){return this.a.u()},
bt(a){var s
if(a==null)s=null
else{s=this.b
s=s.c_(s,a,t.z,this.$ti.y[1])}this.c=s},
dk(a){var s,r=this
r.a.dk(a)
if(a==null)r.d=null
else if(t.r.b(a)){s=r.b
r.d=s.cW(s,a,t.z,t.K,t.l)}else if(t.i6.b(a)){s=r.b
r.d=s.c_(s,a,t.z,t.K)}else throw A.c(A.H(u.y,null))},
kU(a){var s,r,q,p,o,n,m=this,l=m.c
if(l==null)return
s=null
try{s=m.$ti.y[1].a(a)}catch(o){r=A.E(o)
q=A.M(o)
p=m.d
if(p==null){l=m.b
l.b1(l,r,q)}else{l=t.K
n=m.b
if(t.r.b(p))n.jw(p,r,q,l,t.l)
else n.dt(t.i6.a(p),r,l)}return}m.b.dt(l,s,m.$ti.y[1])},
aJ(a){this.a.aJ(a)},
aj(){return this.aJ(null)},
am(){this.a.am()},
$iac:1}
A.cC.prototype={
gA(a){return new A.i5(J.a0(this.gb7()),A.p(this).h("i5<1,2>"))},
gk(a){return J.aM(this.gb7())},
gE(a){return J.kY(this.gb7())},
gaO(a){return J.zE(this.gb7())},
aT(a,b){var s=A.p(this)
return A.i4(J.kZ(this.gb7(),b),s.c,s.y[1])},
bN(a,b){var s=A.p(this)
return A.i4(J.wk(this.gb7(),b),s.c,s.y[1])},
W(a,b){return A.p(this).y[1].a(J.kX(this.gb7(),b))},
V(a,b){return J.wh(this.gb7(),b)},
j(a){return J.bb(this.gb7())}}
A.i5.prototype={
l(){return this.a.l()},
gp(){return this.$ti.y[1].a(this.a.gp())}}
A.cR.prototype={
gb7(){return this.a}}
A.h8.prototype={$ix:1}
A.h2.prototype={
i(a,b){return this.$ti.y[1].a(J.eX(this.a,b))},
m(a,b,c){J.kW(this.a,b,this.$ti.c.a(c))},
sk(a,b){J.zH(this.a,b)},
q(a,b){J.hN(this.a,this.$ti.c.a(b))},
cM(a,b){var s=b==null?null:new A.qZ(this,b)
J.wj(this.a,s)},
Y(a,b,c,d,e){var s=this.$ti
J.zI(this.a,b,c,A.i4(d,s.y[1],s.c),e)},
af(a,b,c,d){return this.Y(0,b,c,d,0)},
$ix:1,
$it:1}
A.qZ.prototype={
$2(a,b){var s=this.a.$ti.y[1]
return this.b.$2(s.a(a),s.a(b))},
$S(){return this.a.$ti.h("a(1,1)")}}
A.ae.prototype={
e6(a,b){return new A.ae(this.a,this.$ti.h("@<1>").I(b).h("ae<1,2>"))},
gb7(){return this.a}}
A.cS.prototype={
bl(a,b,c){return new A.cS(this.a,this.$ti.h("@<1,2>").I(b).I(c).h("cS<1,2,3,4>"))},
F(a){return this.a.F(a)},
i(a,b){return this.$ti.h("4?").a(this.a.i(0,b))},
ad(a,b){this.a.ad(0,new A.lC(this,b))},
ga3(){var s=this.$ti
return A.i4(this.a.ga3(),s.c,s.y[2])},
gk(a){var s=this.a
return s.gk(s)},
gE(a){var s=this.a
return s.gE(s)},
gbm(){var s=this.a.gbm()
return s.ba(s,new A.lB(this),this.$ti.h("K<3,4>"))}}
A.lC.prototype={
$2(a,b){var s=this.a.$ti
this.b.$2(s.y[2].a(a),s.y[3].a(b))},
$S(){return this.a.$ti.h("~(1,2)")}}
A.lB.prototype={
$1(a){var s=this.a.$ti
return new A.K(s.y[2].a(a.a),s.y[3].a(a.b),s.h("K<3,4>"))},
$S(){return this.a.$ti.h("K<3,4>(K<1,2>)")}}
A.d1.prototype={
j(a){return"LateInitializationError: "+this.a}}
A.bn.prototype={
gk(a){return this.a.length},
i(a,b){return this.a.charCodeAt(b)}}
A.uN.prototype={
$0(){return A.n2(null,t.H)},
$S:3}
A.ou.prototype={}
A.x.prototype={}
A.X.prototype={
gA(a){var s=this
return new A.as(s,s.gk(s),A.p(s).h("as<X.E>"))},
gE(a){return this.gk(this)===0},
gai(a){if(this.gk(this)===0)throw A.c(A.bW())
return this.W(0,0)},
V(a,b){var s,r=this,q=r.gk(r)
for(s=0;s<q;++s){if(J.A(r.W(0,s),b))return!0
if(q!==r.gk(r))throw A.c(A.am(r))}return!1},
bp(a,b){var s,r,q,p=this,o=p.gk(p)
if(b.length!==0){if(o===0)return""
s=A.q(p.W(0,0))
if(o!==p.gk(p))throw A.c(A.am(p))
for(r=s,q=1;q<o;++q){r=r+b+A.q(p.W(0,q))
if(o!==p.gk(p))throw A.c(A.am(p))}return r.charCodeAt(0)==0?r:r}else{for(q=0,r="";q<o;++q){r+=A.q(p.W(0,q))
if(o!==p.gk(p))throw A.c(A.am(p))}return r.charCodeAt(0)==0?r:r}},
o3(a){return this.bp(0,"")},
ba(a,b,c){return new A.a8(this,b,A.p(this).h("@<X.E>").I(c).h("a8<1,2>"))},
ox(a,b){var s,r,q=this,p=q.gk(q)
if(p===0)throw A.c(A.bW())
s=q.W(0,0)
for(r=1;r<p;++r){s=b.$2(s,q.W(0,r))
if(p!==q.gk(q))throw A.c(A.am(q))}return s},
aT(a,b){return A.bJ(this,b,null,A.p(this).h("X.E"))},
bN(a,b){return A.bJ(this,0,A.bA(b,"count",t.S),A.p(this).h("X.E"))},
du(a){var s,r=this,q=A.vj(A.p(r).h("X.E"))
for(s=0;s<r.gk(r);++s)q.q(0,r.W(0,s))
return q}}
A.dd.prototype={
kJ(a,b,c,d){var s,r=this.b
A.aH(r,"start")
s=this.c
if(s!=null){A.aH(s,"end")
if(r>s)throw A.c(A.ab(r,0,s,"start",null))}},
glf(){var s=J.aM(this.a),r=this.c
if(r==null||r>s)return s
return r},
gmj(){var s=J.aM(this.a),r=this.b
if(r>s)return s
return r},
gk(a){var s,r=J.aM(this.a),q=this.b
if(q>=r)return 0
s=this.c
if(s==null||s>=r)return r-q
return s-q},
W(a,b){var s=this,r=s.gmj()+b
if(b<0||r>=s.glf())throw A.c(A.it(b,s.gk(0),s,null,"index"))
return J.kX(s.a,r)},
aT(a,b){var s,r,q=this
A.aH(b,"count")
s=q.b+b
r=q.c
if(r!=null&&s>=r)return new A.cY(q.$ti.h("cY<1>"))
return A.bJ(q.a,s,r,q.$ti.c)},
bN(a,b){var s,r,q,p=this
A.aH(b,"count")
s=p.c
r=p.b
if(s==null)return A.bJ(p.a,r,B.b.dw(r,b),p.$ti.c)
else{q=B.b.dw(r,b)
if(s<q)return p
return A.bJ(p.a,r,q,p.$ti.c)}},
ca(a,b){var s,r,q,p=this,o=p.b,n=p.a,m=J.aa(n),l=m.gk(n),k=p.c
if(k!=null&&k<l)l=k
s=l-o
if(s<=0){n=p.$ti.c
return b?J.vd(0,n):J.vc(0,n)}r=A.b4(s,m.W(n,o),b,p.$ti.c)
for(q=1;q<s;++q){r[q]=m.W(n,o+q)
if(m.gk(n)<l)throw A.c(A.am(p))}return r}}
A.as.prototype={
gp(){var s=this.d
return s==null?this.$ti.c.a(s):s},
l(){var s,r=this,q=r.a,p=J.aa(q),o=p.gk(q)
if(r.b!==o)throw A.c(A.am(q))
s=r.c
if(s>=o){r.d=null
return!1}r.d=p.W(q,s);++r.c
return!0}}
A.bY.prototype={
gA(a){return new A.cr(J.a0(this.a),this.b,A.p(this).h("cr<1,2>"))},
gk(a){return J.aM(this.a)},
gE(a){return J.kY(this.a)},
W(a,b){return this.b.$1(J.kX(this.a,b))}}
A.bU.prototype={$ix:1}
A.cr.prototype={
l(){var s=this,r=s.b
if(r.l()){s.a=s.c.$1(r.gp())
return!0}s.a=null
return!1},
gp(){var s=this.a
return s==null?this.$ti.y[1].a(s):s}}
A.a8.prototype={
gk(a){return J.aM(this.a)},
W(a,b){return this.b.$1(J.kX(this.a,b))}}
A.c7.prototype={
gA(a){return new A.ek(J.a0(this.a),this.b)},
ba(a,b,c){return new A.bY(this,b,this.$ti.h("@<1>").I(c).h("bY<1,2>"))}}
A.ek.prototype={
l(){var s,r
for(s=this.a,r=this.b;s.l();)if(r.$1(s.gp()))return!0
return!1},
gp(){return this.a.gp()}}
A.fe.prototype={
gA(a){return new A.il(J.a0(this.a),this.b,B.a1,this.$ti.h("il<1,2>"))}}
A.il.prototype={
gp(){var s=this.d
return s==null?this.$ti.y[1].a(s):s},
l(){var s,r,q=this,p=q.c
if(p==null)return!1
for(s=q.a,r=q.b;!p.l();){q.d=null
if(s.l()){q.c=null
p=J.a0(r.$1(s.gp()))
q.c=p}else return!1}q.d=q.c.gp()
return!0}}
A.df.prototype={
gA(a){var s=this.a
return new A.jo(s.gA(s),this.b,A.p(this).h("jo<1>"))}}
A.fc.prototype={
gk(a){var s=this.a,r=s.gk(s)
s=this.b
if(B.b.kd(r,s))return s
return r},
$ix:1}
A.jo.prototype={
l(){if(--this.b>=0)return this.a.l()
this.b=-1
return!1},
gp(){if(this.b<0){this.$ti.c.a(null)
return null}return this.a.gp()}}
A.c0.prototype={
aT(a,b){A.hQ(b,"count")
A.aH(b,"count")
return new A.c0(this.a,this.b+b,A.p(this).h("c0<1>"))},
gA(a){var s=this.a
return new A.j7(s.gA(s),this.b)}}
A.dQ.prototype={
gk(a){var s=this.a,r=s.gk(s)-this.b
if(r>=0)return r
return 0},
aT(a,b){A.hQ(b,"count")
A.aH(b,"count")
return new A.dQ(this.a,this.b+b,this.$ti)},
$ix:1}
A.j7.prototype={
l(){var s,r
for(s=this.a,r=0;r<this.b;++r)s.l()
this.b=0
return s.l()},
gp(){return this.a.gp()}}
A.cY.prototype={
gA(a){return B.a1},
gE(a){return!0},
gk(a){return 0},
W(a,b){throw A.c(A.ab(b,0,0,"index",null))},
V(a,b){return!1},
ba(a,b,c){return new A.cY(c.h("cY<0>"))},
aT(a,b){A.aH(b,"count")
return this},
bN(a,b){A.aH(b,"count")
return this},
ca(a,b){var s=this.$ti.c
return b?J.vd(0,s):J.vc(0,s)}}
A.ih.prototype={
l(){return!1},
gp(){throw A.c(A.bW())}}
A.fX.prototype={
gA(a){return new A.jD(J.a0(this.a),this.$ti.h("jD<1>"))}}
A.jD.prototype={
l(){var s,r
for(s=this.a,r=this.$ti.c;s.l();)if(r.b(s.gp()))return!0
return!1},
gp(){return this.$ti.c.a(this.a.gp())}}
A.fB.prototype={
ghP(){var s,r,q
for(s=this.a,r=A.p(s),s=new A.cr(J.a0(s.a),s.b,r.h("cr<1,2>")),r=r.y[1];s.l();){q=s.a
if(q==null)q=r.a(q)
if(q!=null)return q}return null},
gE(a){return this.ghP()==null},
gaO(a){return this.ghP()!=null},
gA(a){var s=this.a
return new A.iQ(new A.cr(J.a0(s.a),s.b,A.p(s).h("cr<1,2>")))}}
A.iQ.prototype={
l(){var s,r,q
this.b=null
for(s=this.a,r=s.$ti.y[1];s.l();){q=s.a
if(q==null)q=r.a(q)
if(q!=null){this.b=q
return!0}}return!1},
gp(){var s=this.b
return s==null?A.r(A.bW()):s}}
A.fh.prototype={
sk(a,b){throw A.c(A.R(u.O))},
q(a,b){throw A.c(A.R("Cannot add to a fixed-length list"))}}
A.jt.prototype={
m(a,b,c){throw A.c(A.R("Cannot modify an unmodifiable list"))},
sk(a,b){throw A.c(A.R("Cannot change the length of an unmodifiable list"))},
q(a,b){throw A.c(A.R("Cannot add to an unmodifiable list"))},
cM(a,b){throw A.c(A.R("Cannot modify an unmodifiable list"))},
Y(a,b,c,d,e){throw A.c(A.R("Cannot modify an unmodifiable list"))},
af(a,b,c,d){return this.Y(0,b,c,d,0)}}
A.eg.prototype={}
A.da.prototype={
gk(a){return J.aM(this.a)},
W(a,b){var s=this.a,r=J.aa(s)
return r.W(s,r.gk(s)-1-b)}}
A.fM.prototype={
gv(a){var s=this._hashCode
if(s!=null)return s
s=664597*B.a.gv(this.a)&536870911
this._hashCode=s
return s},
j(a){return'Symbol("'+A.B7(this)+'")'},
D(a,b){if(b==null)return!1
return b instanceof A.fM&&this.a===b.a}}
A.hF.prototype={}
A.hn.prototype={$r:"+immediateRestart(1)",$s:1}
A.N.prototype={$r:"+(1,2)",$s:2}
A.ho.prototype={$r:"+basicSupport,supportsReadWriteUnsafe(1,2)",$s:3}
A.hp.prototype={$r:"+controller,sync(1,2)",$s:4}
A.kd.prototype={$r:"+downloaded,total(1,2)",$s:5}
A.eE.prototype={$r:"+file,outFlags(1,2)",$s:6}
A.ke.prototype={$r:"+name,parameters(1,2)",$s:7}
A.kf.prototype={$r:"+result,resultCode(1,2)",$s:8}
A.hq.prototype={$r:"+(1,2,3)",$s:9}
A.kg.prototype={$r:"+autocommit,lastInsertRowid,result(1,2,3)",$s:10}
A.kh.prototype={$r:"+connectName,connectPort,lockName(1,2,3)",$s:11}
A.ki.prototype={$r:"+hasSynced,lastSyncedAt,priority(1,2,3)",$s:12}
A.kj.prototype={$r:"+atLast,priority,sinceLast,targetCount(1,2,3,4)",$s:13}
A.f4.prototype={
bl(a,b,c){var s=A.p(this)
return A.wQ(this,s.c,s.y[1],b,c)},
gE(a){return this.gk(this)===0},
j(a){return A.nP(this)},
gbm(){return new A.eI(this.nr(),A.p(this).h("eI<K<1,2>>"))},
nr(){var s=this
return function(){var r=0,q=1,p=[],o,n,m
return function $async$gbm(a,b,c){if(b===1){p.push(c)
r=q}for(;;)switch(r){case 0:o=s.ga3(),o=o.gA(o),n=A.p(s).h("K<1,2>")
case 2:if(!o.l()){r=3
break}m=o.gp()
r=4
return a.b=new A.K(m,s.i(0,m),n),1
case 4:r=2
break
case 3:return 0
case 1:return a.c=p.at(-1),3}}}},
cz(a,b,c,d){var s=A.T(c,d)
this.ad(0,new A.lX(this,b,s))
return s},
$ia3:1}
A.lX.prototype={
$2(a,b){var s=this.b.$2(a,b)
this.c.m(0,s.a,s.b)},
$S(){return A.p(this.a).h("~(1,2)")}}
A.bo.prototype={
gk(a){return this.b.length},
gi_(){var s=this.$keys
if(s==null){s=Object.keys(this.a)
this.$keys=s}return s},
F(a){if(typeof a!="string")return!1
if("__proto__"===a)return!1
return this.a.hasOwnProperty(a)},
i(a,b){if(!this.F(b))return null
return this.b[this.a[b]]},
ad(a,b){var s,r,q=this.gi_(),p=this.b
for(s=q.length,r=0;r<s;++r)b.$2(q[r],p[r])},
ga3(){return new A.he(this.gi_(),this.$ti.h("he<1>"))}}
A.he.prototype={
gk(a){return this.a.length},
gE(a){return 0===this.a.length},
gaO(a){return 0!==this.a.length},
gA(a){var s=this.a
return new A.ey(s,s.length,this.$ti.h("ey<1>"))}}
A.ey.prototype={
gp(){var s=this.d
return s==null?this.$ti.c.a(s):s},
l(){var s=this,r=s.c
if(r>=s.b){s.d=null
return!1}s.d=s.a[r]
s.c=r+1
return!0}}
A.f5.prototype={
q(a,b){A.A0()}}
A.f6.prototype={
gk(a){return this.b},
gE(a){return this.b===0},
gaO(a){return this.b!==0},
gA(a){var s,r=this,q=r.$keys
if(q==null){q=Object.keys(r.a)
r.$keys=q}s=q
return new A.ey(s,s.length,r.$ti.h("ey<1>"))},
V(a,b){if("__proto__"===b)return!1
return this.a.hasOwnProperty(b)},
du(a){return A.Aw(this,this.$ti.c)}}
A.ny.prototype={
D(a,b){if(b==null)return!1
return b instanceof A.fm&&this.a.D(0,b.a)&&A.w4(this)===A.w4(b)},
gv(a){return A.c_(this.a,A.w4(this),B.d,B.d,B.d,B.d)},
j(a){var s=B.c.bp([A.bj(this.$ti.c)],", ")
return this.a.j(0)+" with "+("<"+s+">")}}
A.fm.prototype={
$1(a){return this.a.$1$1(a,this.$ti.y[0])},
$2(a,b){return this.a.$1$2(a,b,this.$ti.y[0])},
$S(){return A.E4(A.kN(this.a),this.$ti)}}
A.fD.prototype={}
A.px.prototype={
bb(a){var s,r,q=this,p=new RegExp(q.a).exec(a)
if(p==null)return null
s=Object.create(null)
r=q.b
if(r!==-1)s.arguments=p[r+1]
r=q.c
if(r!==-1)s.argumentsExpr=p[r+1]
r=q.d
if(r!==-1)s.expr=p[r+1]
r=q.e
if(r!==-1)s.method=p[r+1]
r=q.f
if(r!==-1)s.receiver=p[r+1]
return s}}
A.fC.prototype={
j(a){return"Null check operator used on a null value"}}
A.iz.prototype={
j(a){var s,r=this,q="NoSuchMethodError: method not found: '",p=r.b
if(p==null)return"NoSuchMethodError: "+r.a
s=r.c
if(s==null)return q+p+"' ("+r.a+")"
return q+p+"' on '"+s+"' ("+r.a+")"}}
A.js.prototype={
j(a){var s=this.a
return s.length===0?"Error":"Error: "+s}}
A.iS.prototype={
j(a){return"Throw of null ('"+(this.a===null?"null":"undefined")+"' from JavaScript)"},
$iJ:1}
A.fd.prototype={}
A.ht.prototype={
j(a){var s,r=this.b
if(r!=null)return r
r=this.a
s=r!==null&&typeof r==="object"?r.stack:null
return this.b=s==null?"":s},
$iaj:1}
A.cU.prototype={
j(a){var s=this.constructor,r=s==null?null:s.name
return"Closure '"+A.yX(r==null?"unknown":r)+"'"},
ga4(a){var s=A.kN(this)
return A.bj(s==null?A.ba(this):s)},
gpC(){return this},
$C:"$1",
$R:1,
$D:null}
A.lI.prototype={$C:"$0",$R:0}
A.lJ.prototype={$C:"$2",$R:2}
A.pm.prototype={}
A.oF.prototype={
j(a){var s=this.$static_name
if(s==null)return"Closure of unknown static method"
return"Closure '"+A.yX(s)+"'"}}
A.eZ.prototype={
D(a,b){if(b==null)return!1
if(this===b)return!0
if(!(b instanceof A.eZ))return!1
return this.$_target===b.$_target&&this.a===b.a},
gv(a){return(A.kP(this.a)^A.e3(this.$_target))>>>0},
j(a){return"Closure '"+this.$_name+"' of "+("Instance of '"+A.iY(this.a)+"'")}}
A.j4.prototype={
j(a){return"RuntimeError: "+this.a}}
A.b1.prototype={
gk(a){return this.a},
gE(a){return this.a===0},
ga3(){return new A.b2(this,A.p(this).h("b2<1>"))},
gbm(){return new A.aF(this,A.p(this).h("aF<1,2>"))},
F(a){var s,r
if(typeof a=="string"){s=this.b
if(s==null)return!1
return s[a]!=null}else if(typeof a=="number"&&(a&0x3fffffff)===a){r=this.c
if(r==null)return!1
return r[a]!=null}else return this.jb(a)},
jb(a){var s=this.d
if(s==null)return!1
return this.cv(this.hU(s,a),a)>=0},
a7(a,b){b.ad(0,new A.nG(this))},
i(a,b){var s,r,q,p,o=null
if(typeof b=="string"){s=this.b
if(s==null)return o
r=s[b]
q=r==null?o:r.b
return q}else if(typeof b=="number"&&(b&0x3fffffff)===b){p=this.c
if(p==null)return o
r=p[b]
q=r==null?o:r.b
return q}else return this.jc(b)},
jc(a){var s,r,q=this.d
if(q==null)return null
s=this.hU(q,a)
r=this.cv(s,a)
if(r<0)return null
return s[r].b},
m(a,b,c){var s,r,q=this
if(typeof b=="string"){s=q.b
q.hs(s==null?q.b=q.fk():s,b,c)}else if(typeof b=="number"&&(b&0x3fffffff)===b){r=q.c
q.hs(r==null?q.c=q.fk():r,b,c)}else q.je(b,c)},
je(a,b){var s,r,q,p=this,o=p.d
if(o==null)o=p.d=p.fk()
s=p.di(a)
r=o[s]
if(r==null)o[s]=[p.fl(a,b)]
else{q=p.cv(r,a)
if(q>=0)r[q].b=b
else r.push(p.fl(a,b))}},
cB(a,b){var s,r,q=this
if(q.F(a)){s=q.i(0,a)
return s==null?A.p(q).y[1].a(s):s}r=b.$0()
q.m(0,a,r)
return r},
H(a,b){var s=this
if(typeof b=="string")return s.ic(s.b,b)
else if(typeof b=="number"&&(b&0x3fffffff)===b)return s.ic(s.c,b)
else return s.jd(b)},
jd(a){var s,r,q,p,o=this,n=o.d
if(n==null)return null
s=o.di(a)
r=n[s]
q=o.cv(r,a)
if(q<0)return null
p=r.splice(q,1)[0]
o.iu(p)
if(r.length===0)delete n[s]
return p.b},
aF(a){var s=this
if(s.a>0){s.b=s.c=s.d=s.e=s.f=null
s.a=0
s.fj()}},
ad(a,b){var s=this,r=s.e,q=s.r
while(r!=null){b.$2(r.a,r.b)
if(q!==s.r)throw A.c(A.am(s))
r=r.c}},
hs(a,b,c){var s=a[b]
if(s==null)a[b]=this.fl(b,c)
else s.b=c},
ic(a,b){var s
if(a==null)return null
s=a[b]
if(s==null)return null
this.iu(s)
delete a[b]
return s.b},
fj(){this.r=this.r+1&1073741823},
fl(a,b){var s,r=this,q=new A.nJ(a,b)
if(r.e==null)r.e=r.f=q
else{s=r.f
s.toString
q.d=s
r.f=s.c=q}++r.a
r.fj()
return q},
iu(a){var s=this,r=a.d,q=a.c
if(r==null)s.e=q
else r.c=q
if(q==null)s.f=r
else q.d=r;--s.a
s.fj()},
di(a){return J.U(a)&1073741823},
hU(a,b){return a[this.di(b)]},
cv(a,b){var s,r
if(a==null)return-1
s=a.length
for(r=0;r<s;++r)if(J.A(a[r].a,b))return r
return-1},
j(a){return A.nP(this)},
fk(){var s=Object.create(null)
s["<non-identifier-key>"]=s
delete s["<non-identifier-key>"]
return s}}
A.nG.prototype={
$2(a,b){this.a.m(0,a,b)},
$S(){return A.p(this.a).h("~(1,2)")}}
A.nJ.prototype={}
A.b2.prototype={
gk(a){return this.a.a},
gE(a){return this.a.a===0},
gA(a){var s=this.a
return new A.d2(s,s.r,s.e)},
V(a,b){return this.a.F(b)}}
A.d2.prototype={
gp(){return this.d},
l(){var s,r=this,q=r.a
if(r.b!==q.r)throw A.c(A.am(q))
s=r.c
if(s==null){r.d=null
return!1}else{r.d=s.a
r.c=s.c
return!0}}}
A.bX.prototype={
gk(a){return this.a.a},
gE(a){return this.a.a===0},
gA(a){var s=this.a
return new A.b3(s,s.r,s.e)}}
A.b3.prototype={
gp(){return this.d},
l(){var s,r=this,q=r.a
if(r.b!==q.r)throw A.c(A.am(q))
s=r.c
if(s==null){r.d=null
return!1}else{r.d=s.b
r.c=s.c
return!0}}}
A.aF.prototype={
gk(a){return this.a.a},
gE(a){return this.a.a===0},
gA(a){var s=this.a
return new A.iG(s,s.r,s.e,this.$ti.h("iG<1,2>"))}}
A.iG.prototype={
gp(){var s=this.d
s.toString
return s},
l(){var s,r=this,q=r.a
if(r.b!==q.r)throw A.c(A.am(q))
s=r.c
if(s==null){r.d=null
return!1}else{r.d=new A.K(s.a,s.b,r.$ti.h("K<1,2>"))
r.c=s.c
return!0}}}
A.fp.prototype={
di(a){return A.kP(a)&1073741823},
cv(a,b){var s,r,q
if(a==null)return-1
s=a.length
for(r=0;r<s;++r){q=a[r].a
if(q==null?b==null:q===b)return r}return-1}}
A.ux.prototype={
$1(a){return this.a(a)},
$S:41}
A.uy.prototype={
$2(a,b){return this.a(a,b)},
$S:139}
A.uz.prototype={
$1(a){return this.a(a)},
$S:109}
A.hm.prototype={
ga4(a){return A.bj(this.hV())},
hV(){return A.DS(this.$r,this.cS())},
j(a){return this.it(!1)},
it(a){var s,r,q,p,o,n=this.lk(),m=this.cS(),l=(a?"Record ":"")+"("
for(s=n.length,r="",q=0;q<s;++q,r=", "){l+=r
p=n[q]
if(typeof p=="string")l=l+p+": "
o=m[q]
l=a?l+A.x3(o):l+A.q(o)}l+=")"
return l.charCodeAt(0)==0?l:l},
lk(){var s,r=this.$s
while($.tc.length<=r)$.tc.push(null)
s=$.tc[r]
if(s==null){s=this.l6()
$.tc[r]=s}return s},
l6(){var s,r,q,p=this.$r,o=p.indexOf("("),n=p.substring(1,o),m=p.substring(o),l=m==="()"?0:m.replace(/[^,]/g,"").length+1,k=A.u(new Array(l),t.hf)
for(s=0;s<l;++s)k[s]=s
if(n!==""){r=n.split(",")
s=r.length
for(q=l;s>0;){--q;--s
k[q]=r[s]}}return A.nM(k,t.K)}}
A.ka.prototype={
cS(){return[this.a,this.b]},
D(a,b){if(b==null)return!1
return b instanceof A.ka&&this.$s===b.$s&&J.A(this.a,b.a)&&J.A(this.b,b.b)},
gv(a){return A.c_(this.$s,this.a,this.b,B.d,B.d,B.d)}}
A.k9.prototype={
cS(){return[this.a]},
D(a,b){if(b==null)return!1
return b instanceof A.k9&&this.$s===b.$s&&J.A(this.a,b.a)},
gv(a){return A.c_(this.$s,this.a,B.d,B.d,B.d,B.d)}}
A.kb.prototype={
cS(){return[this.a,this.b,this.c]},
D(a,b){var s=this
if(b==null)return!1
return b instanceof A.kb&&s.$s===b.$s&&J.A(s.a,b.a)&&J.A(s.b,b.b)&&J.A(s.c,b.c)},
gv(a){var s=this
return A.c_(s.$s,s.a,s.b,s.c,B.d,B.d)}}
A.kc.prototype={
cS(){return this.a},
D(a,b){if(b==null)return!1
return b instanceof A.kc&&this.$s===b.$s&&A.C5(this.a,b.a)},
gv(a){return A.c_(this.$s,A.AG(this.a),B.d,B.d,B.d,B.d)}}
A.fo.prototype={
j(a){return"RegExp/"+this.a+"/"+this.b.flags},
glG(){var s=this,r=s.c
if(r!=null)return r
r=s.b
return s.c=A.vf(s.a,r.multiline,!r.ignoreCase,r.unicode,r.dotAll,"g")},
glF(){var s=this,r=s.d
if(r!=null)return r
r=s.b
return s.d=A.vf(s.a,r.multiline,!r.ignoreCase,r.unicode,r.dotAll,"y")},
j0(a){var s=this.b.exec(a)
if(s==null)return null
return new A.eC(s)},
fA(a,b,c){var s=b.length
if(c>s)throw A.c(A.ab(c,0,s,null,null))
return new A.jH(this,b,c)},
e2(a,b){return this.fA(0,b,0)},
lj(a,b){var s,r=this.glG()
r.lastIndex=b
s=r.exec(a)
if(s==null)return null
return new A.eC(s)},
li(a,b){var s,r=this.glF()
r.lastIndex=b
s=r.exec(a)
if(s==null)return null
return new A.eC(s)},
cA(a,b,c){if(c<0||c>b.length)throw A.c(A.ab(c,0,b.length,null,null))
return this.li(b,c)}}
A.eC.prototype={
gC(){var s=this.b
return s.index+s[0].length},
i(a,b){return this.b[b]},
$id4:1,
$ij_:1}
A.jH.prototype={
gA(a){return new A.jI(this.a,this.b,this.c)}}
A.jI.prototype={
gp(){var s=this.d
return s==null?t.lu.a(s):s},
l(){var s,r,q,p,o,n,m=this,l=m.b
if(l==null)return!1
s=m.c
r=l.length
if(s<=r){q=m.a
p=q.lj(l,s)
if(p!=null){m.d=p
o=p.gC()
if(p.b.index===o){s=!1
if(q.b.unicode){q=m.c
n=q+1
if(n<r){r=l.charCodeAt(q)
if(r>=55296&&r<=56319){s=l.charCodeAt(n)
s=s>=56320&&s<=57343}}}o=(s?o+1:o)+1}m.c=o
return!0}}m.b=m.d=null
return!1}}
A.fL.prototype={
gC(){return this.a+this.c.length},
i(a,b){if(b!==0)throw A.c(A.oc(b,null))
return this.c},
$id4:1}
A.kt.prototype={
gA(a){return new A.tr(this.a,this.b,this.c)}}
A.tr.prototype={
l(){var s,r,q=this,p=q.c,o=q.b,n=o.length,m=q.a,l=m.length
if(p+n>l){q.d=null
return!1}s=m.indexOf(o,p)
if(s<0){q.c=l+1
q.d=null
return!1}r=s+n
q.d=new A.fL(s,o)
q.c=r===q.c?r+1:r
return!0},
gp(){var s=this.d
s.toString
return s}}
A.jR.prototype={
dQ(){var s=this.b
if(s===this)throw A.c(new A.d1("Local '"+this.a+"' has not been initialized."))
return s},
aV(){var s=this.b
if(s===this)throw A.c(A.wM(this.a))
return s}}
A.e_.prototype={
gjf(a){return a.byteLength},
ga4(a){return B.bF},
e3(a,b,c){A.kG(a,b,c)
return c==null?new Uint8Array(a,b):new Uint8Array(a,b,c)},
iF(a){return this.e3(a,0,null)},
$ia_:1,
$icP:1}
A.bE.prototype={$ibE:1}
A.fy.prototype={
gau(a){if(((a.$flags|0)&2)!==0)return new A.kA(a.buffer)
else return a.buffer},
lx(a,b,c,d){var s=A.ab(b,0,c,d,null)
throw A.c(s)},
hx(a,b,c,d){if(b>>>0!==b||b>c)this.lx(a,b,c,d)}}
A.kA.prototype={
gjf(a){return this.a.byteLength},
e3(a,b,c){var s=A.aU(this.a,b,c)
s.$flags=3
return s},
iF(a){return this.e3(0,0,null)},
$icP:1}
A.fx.prototype={
ga4(a){return B.bG},
$ia_:1,
$iv4:1}
A.e0.prototype={
gk(a){return a.length},
ik(a,b,c,d,e){var s,r,q=a.length
this.hx(a,b,q,"start")
this.hx(a,c,q,"end")
if(b>c)throw A.c(A.ab(b,0,c,null,null))
s=c-b
if(e<0)throw A.c(A.H(e,null))
r=d.length
if(r-e<s)throw A.c(A.z("Not enough elements"))
if(e!==0||r!==s)d=d.subarray(e,e+s)
a.set(d,b)},
$iaE:1,
$ib0:1}
A.cs.prototype={
i(a,b){A.ch(b,a,a.length)
return a[b]},
m(a,b,c){a.$flags&2&&A.B(a)
A.ch(b,a,a.length)
a[b]=c},
Y(a,b,c,d,e){a.$flags&2&&A.B(a,5)
if(t.dQ.b(d)){this.ik(a,b,c,d,e)
return}this.hn(a,b,c,d,e)},
af(a,b,c,d){return this.Y(a,b,c,d,0)},
$ix:1,
$im:1,
$it:1}
A.b5.prototype={
m(a,b,c){a.$flags&2&&A.B(a)
A.ch(b,a,a.length)
a[b]=c},
Y(a,b,c,d,e){a.$flags&2&&A.B(a,5)
if(t.aj.b(d)){this.ik(a,b,c,d,e)
return}this.hn(a,b,c,d,e)},
af(a,b,c,d){return this.Y(a,b,c,d,0)},
$ix:1,
$im:1,
$it:1}
A.iJ.prototype={
ga4(a){return B.bH},
$ia_:1,
$imV:1}
A.iK.prototype={
ga4(a){return B.bI},
$ia_:1,
$imW:1}
A.iL.prototype={
ga4(a){return B.bJ},
i(a,b){A.ch(b,a,a.length)
return a[b]},
$ia_:1,
$inz:1}
A.iM.prototype={
ga4(a){return B.bK},
i(a,b){A.ch(b,a,a.length)
return a[b]},
$ia_:1,
$inA:1}
A.iN.prototype={
ga4(a){return B.bL},
i(a,b){A.ch(b,a,a.length)
return a[b]},
$ia_:1,
$inB:1}
A.iO.prototype={
ga4(a){return B.bO},
i(a,b){A.ch(b,a,a.length)
return a[b]},
$ia_:1,
$ipz:1}
A.fz.prototype={
ga4(a){return B.bP},
i(a,b){A.ch(b,a,a.length)
return a[b]},
bQ(a,b,c){return new Uint32Array(a.subarray(b,A.ya(b,c,a.length)))},
$ia_:1,
$ipA:1}
A.fA.prototype={
ga4(a){return B.bQ},
gk(a){return a.length},
i(a,b){A.ch(b,a,a.length)
return a[b]},
$ia_:1,
$ipB:1}
A.d5.prototype={
ga4(a){return B.bR},
gk(a){return a.length},
i(a,b){A.ch(b,a,a.length)
return a[b]},
bQ(a,b,c){return new Uint8Array(a.subarray(b,A.ya(b,c,a.length)))},
$ia_:1,
$id5:1,
$ibe:1}
A.hh.prototype={}
A.hi.prototype={}
A.hj.prototype={}
A.hk.prototype={}
A.br.prototype={
h(a){return A.hA(v.typeUniverse,this,a)},
I(a){return A.xR(v.typeUniverse,this,a)}}
A.jZ.prototype={}
A.ty.prototype={
j(a){return A.b9(this.a,null)}}
A.jV.prototype={
j(a){return this.a}}
A.hw.prototype={$ic3:1}
A.qG.prototype={
$1(a){var s=this.a,r=s.a
s.a=null
r.$0()},
$S:11}
A.qF.prototype={
$1(a){var s,r
this.a.a=a
s=this.b
r=this.c
s.firstChild?s.removeChild(r):s.appendChild(r)},
$S:58}
A.qH.prototype={
$0(){this.a.$0()},
$S:1}
A.qI.prototype={
$0(){this.a.$0()},
$S:1}
A.tw.prototype={
kS(a,b){if(self.setTimeout!=null)this.b=self.setTimeout(A.dD(new A.tx(this,b),0),a)
else throw A.c(A.R("`setTimeout()` not found."))},
u(){if(self.setTimeout!=null){var s=this.b
if(s==null)return
self.clearTimeout(s)
this.b=null}else throw A.c(A.R("Canceling a timer."))}}
A.tx.prototype={
$0(){this.a.b=null
this.b.$0()},
$S:0}
A.h_.prototype={
U(a){var s,r=this
if(a==null)a=r.$ti.c.a(a)
if(!r.b)r.a.aD(a)
else{s=r.a
if(r.$ti.h("n<1>").b(a))s.hw(a)
else s.bT(a)}},
L(){return this.U(null)},
b8(a,b){var s
if(b==null)b=A.cj(a)
s=this.a
if(this.b)s.ac(new A.a2(a,b))
else s.T(new A.a2(a,b))},
a9(a){return this.b8(a,null)},
$icX:1}
A.tQ.prototype={
$1(a){return this.a.$2(0,a)},
$S:12}
A.tR.prototype={
$2(a,b){this.a.$2(1,new A.fd(a,b))},
$S:79}
A.ui.prototype={
$2(a,b){this.a(a,b)},
$S:63}
A.tO.prototype={
$0(){var s=this.a,r=s.a,q=r.b
if((q&1)!==0?(r.ga6().e&4)!==0:(q&2)===0){s.b=!0
return}s=s.c!=null?2:0
this.b.$2(s,null)},
$S:0}
A.tP.prototype={
$1(a){var s=this.a.c!=null?2:0
this.b.$2(s,null)},
$S:11}
A.jK.prototype={
kN(a,b){this.a.d=new A.qN(this,a)}}
A.qN.prototype={
$0(){var s=$.o,r=this.b,q=new A.qO(s,r),p=this.a,o=p.a
o.f=new A.qL(p,q)
o.r=new A.qM(p,s,r)
q.$0()},
$S:0}
A.qO.prototype={
$0(){var s=this.a
s.bD(s,new A.qK(this.b))},
$S:1}
A.qK.prototype={
$0(){this.a.$2(0,null)},
$S:0}
A.qL.prototype={
$0(){var s=this.a
if(s.b){s.b=!1
this.b.$0()}},
$S:0}
A.qM.prototype={
$0(){var s,r=this.a
if((r.a.b&4)===0){r.c=new A.l($.o,t._)
if(r.b){r.b=!1
s=this.b
s.bD(s,new A.qJ(this.c))}return r.c}},
$S:66}
A.qJ.prototype={
$0(){this.a.$2(2,null)},
$S:0}
A.hd.prototype={
j(a){return"IterationMarker("+this.b+", "+A.q(this.a)+")"}}
A.kv.prototype={
gp(){return this.b},
ma(a,b){var s,r,q
a=a
b=b
s=this.a
for(;;)try{r=s(this,a,b)
return r}catch(q){b=q
a=1}},
l(){var s,r,q,p,o=this,n=null,m=0
for(;;){s=o.d
if(s!=null)try{if(s.l()){o.b=s.gp()
return!0}else o.d=null}catch(r){n=r
m=1
o.d=null}q=o.ma(m,n)
if(1===q)return!0
if(0===q){o.b=null
p=o.e
if(p==null||p.length===0){o.a=A.xL
return!1}o.a=p.pop()
m=0
n=null
continue}if(2===q){m=0
n=null
continue}if(3===q){n=o.c
o.c=null
p=o.e
if(p==null||p.length===0){o.b=null
o.a=A.xL
throw n
return!1}o.a=p.pop()
m=1
continue}throw A.c(A.z("sync*"))}return!1},
pE(a){var s,r,q=this
if(a instanceof A.eI){s=a.a()
r=q.e
if(r==null)r=q.e=[]
r.push(q.a)
q.a=s
return 2}else{q.d=J.a0(a)
return 2}}}
A.eI.prototype={
gA(a){return new A.kv(this.a())}}
A.a2.prototype={
j(a){return A.q(this.a)},
$iV:1,
gbz(){return this.b}}
A.ao.prototype={
gaw(){return!0}}
A.dm.prototype={
b2(){},
b3(){}}
A.ca.prototype={
sjk(a){throw A.c(A.R(u.t))},
sjl(a){throw A.c(A.R(u.t))},
gbA(){return new A.ao(this,A.p(this).h("ao<1>"))},
gal(){return this.c<4},
dK(){var s=this.r
return s==null?this.r=new A.l($.o,t.D):s},
ie(a){var s=a.CW,r=a.ch
if(s==null)this.d=r
else s.ch=r
if(r==null)this.e=s
else r.CW=s
a.CW=a
a.ch=a},
fq(a,b,c,d){var s,r,q,p,o,n,m,l,k,j=this
if((j.c&4)!==0)return A.xA(c,A.p(j).c)
s=A.p(j)
r=$.o
q=d?1:0
p=b!=null?32:0
o=A.jN(r,a,s.c)
n=A.jO(r,b)
m=c==null?A.uj():c
l=new A.dm(j,o,n,r.b4(r,m,t.H),r,q|p,s.h("dm<1>"))
l.CW=l
l.ch=l
l.ay=j.c&1
k=j.e
j.e=l
l.ch=null
l.CW=k
if(k==null)j.d=l
else k.ch=l
if(j.d===l)A.kK(j.a)
return l},
i9(a){var s,r=this
A.p(r).h("dm<1>").a(a)
if(a.ch===a)return null
s=a.ay
if((s&2)!==0)a.ay=s|4
else{r.ie(a)
if((r.c&2)===0&&r.d==null)r.eS()}return null},
ia(a){},
ib(a){},
ak(){if((this.c&4)!==0)return new A.aW("Cannot add new events after calling close")
return new A.aW("Cannot add new events while doing an addStream")},
q(a,b){if(!this.gal())throw A.c(this.ak())
this.a2(b)},
ag(a,b){var s
if(!this.gal())throw A.c(this.ak())
s=A.aw(a,b)
this.bj(s.a,s.b)},
n(){var s,r,q=this
if((q.c&4)!==0){s=q.r
s.toString
return s}if(!q.gal())throw A.c(q.ak())
q.c|=4
r=q.dK()
q.bE()
return r},
e1(a,b){var s,r=this
if(!r.gal())throw A.c(r.ak())
r.c|=8
s=A.Bp(r,a,!1)
r.f=s
return s.a},
iD(a){return this.e1(a,null)},
N(a){this.a2(a)},
ab(a,b){this.bj(a,b)},
a_(){var s=this.f
s.toString
this.f=null
this.c&=4294967287
s.a.aD(null)},
f7(a){var s,r,q,p=this,o=p.c
if((o&2)!==0)throw A.c(A.z(u.c))
s=p.d
if(s==null)return
r=o&1
p.c=o^3
while(s!=null){o=s.ay
if((o&1)===r){s.ay=o|2
a.$1(s)
o=s.ay^=1
q=s.ch
if((o&4)!==0)p.ie(s)
s.ay&=4294967293
s=q}else s=s.ch}p.c&=4294967293
if(p.d==null)p.eS()},
eS(){if((this.c&4)!==0){var s=this.r
if((s.a&30)===0)s.aD(null)}A.kK(this.b)},
$iah:1,
$ibG:1,
sjj(a){return this.a=a},
sji(a){return this.b=a}}
A.dw.prototype={
gal(){return A.ca.prototype.gal.call(this)&&(this.c&2)===0},
ak(){if((this.c&2)!==0)return new A.aW(u.c)
return this.ky()},
a2(a){var s=this,r=s.d
if(r==null)return
if(r===s.e){s.c|=2
r.N(a)
s.c&=4294967293
if(s.d==null)s.eS()
return}s.f7(new A.tt(s,a))},
bj(a,b){if(this.d==null)return
this.f7(new A.tv(this,a,b))},
bE(){var s=this
if(s.d!=null)s.f7(new A.tu(s))
else s.r.aD(null)}}
A.tt.prototype={
$1(a){a.N(this.b)},
$S(){return this.a.$ti.h("~(av<1>)")}}
A.tv.prototype={
$1(a){a.ab(this.b,this.c)},
$S(){return this.a.$ti.h("~(av<1>)")}}
A.tu.prototype={
$1(a){a.a_()},
$S(){return this.a.$ti.h("~(av<1>)")}}
A.h0.prototype={
a2(a){var s
for(s=this.d;s!=null;s=s.ch)s.be(new A.bv(a))},
bj(a,b){var s
for(s=this.d;s!=null;s=s.ch)s.be(new A.es(a,b))},
bE(){var s=this.d
if(s!=null)for(;s!=null;s=s.ch)s.be(B.y)
else this.r.aD(null)}}
A.n3.prototype={
$0(){var s,r,q,p,o,n,m=null
try{m=this.a.$0()}catch(q){s=A.E(q)
r=A.M(q)
p=s
o=r
n=A.dA(p,o)
if(n==null)p=new A.a2(p,o)
else p=n
this.b.ac(p)
return}this.b.bf(m)},
$S:0}
A.n6.prototype={
$2(a,b){var s=this,r=s.a,q=--r.b
if(r.a!=null){r.a=null
r.d=a
r.c=b
if(q===0||s.c)s.d.ac(new A.a2(a,b))}else if(q===0&&!s.c){q=r.d
q.toString
r=r.c
r.toString
s.d.ac(new A.a2(q,r))}},
$S:6}
A.n5.prototype={
$1(a){var s,r,q,p,o,n,m=this,l=m.a,k=--l.b,j=l.a
if(j!=null){J.kW(j,m.b,a)
if(J.A(k,0)){l=m.d
s=A.u([],l.h("w<0>"))
for(q=j,p=q.length,o=0;o<q.length;q.length===p||(0,A.a6)(q),++o){r=q[o]
n=r
if(n==null)n=l.a(n)
J.hN(s,n)}m.c.bT(s)}}else if(J.A(k,0)&&!m.f){s=l.d
s.toString
l=l.c
l.toString
m.c.ac(new A.a2(s,l))}},
$S(){return this.d.h("D(0)")}}
A.mX.prototype={
$2(a,b){if(!this.a.b(a))throw A.c(a)
return this.c.$2(a,b)},
$S(){return this.d.h("0/(k,aj)")}}
A.jp.prototype={
j(a){var s=this.b.j(0)
return"TimeoutException after "+s+": "+this.a},
$iJ:1}
A.mY.prototype={
$1(a){var s,r,q,p,o,n,m=this
if(a===0){s=A.u([],m.c.h("w<0>"))
for(r=m.b,q=r.length,p=0;p<r.length;r.length===q||(0,A.a6)(r),++p){o=r[p]
n=o.b
if(n==null)o.$ti.c.a(n)
s.push(n)}m.a.U(s)}else{s=A.u([],t.b9)
for(r=m.b,q=r.length,p=0;p<r.length;r.length===q||(0,A.a6)(r),++p)s.push(r[p].c)
q=A.u([],m.c.h("w<0?>"))
for(n=r.length,p=0;p<r.length;r.length===n||(0,A.a6)(r),++p)q.push(r[p].b)
m.a.a9(new A.e1(B.c.j1(s,A.DC()),a))}},
$S:8}
A.n1.prototype={
$1(a){var s=this,r=s.a,q=s.b
if(a===0)r.U(new A.N(q.gjA(),s.c.gjA()))
else{q=q.c
r.a9(new A.e1(q==null?s.c.c:q,a))}},
$S:8}
A.e1.prototype={
j(a){var s,r,q="ParallelWaitError",p=this.c
if(p==null){p=this.d
s=p<=1
if(s)return q
return"ParallelWaitError("+p+" errors)"}s=this.d
r=s>1
if(r)s="("+s+" errors)"
else s=""
return q+s+": "+A.q(p.a)},
gbz(){var s=this.c
s=s==null?null:s.b
return s==null?A.V.prototype.gbz.call(this):s}}
A.bM.prototype={
gjA(){var s=this.b
if(s==null)this.$ti.c.a(s)
return s},
ms(a){this.a.bc(new A.rx(this,a),new A.ry(this,a),t.P)}}
A.rx.prototype={
$1(a){this.a.b=a
this.b.$1(0)},
$S(){return this.a.$ti.h("D(1)")}}
A.ry.prototype={
$2(a,b){this.a.c=new A.a2(a,b)
this.b.$1(1)},
$S:7}
A.rw.prototype={
$1(a){var s=this.a,r=s.a+=a
if(++s.b===this.b.length)this.c.$1(r)},
$S:8}
A.dn.prototype={
b8(a,b){if((this.a.a&30)!==0)throw A.c(A.z("Future already completed"))
this.ac(A.aw(a,b))},
a9(a){return this.b8(a,null)},
$icX:1}
A.a9.prototype={
U(a){var s=this.a
if((s.a&30)!==0)throw A.c(A.z("Future already completed"))
s.aD(a)},
L(){return this.U(null)},
ac(a){this.a.T(a)}}
A.L.prototype={
U(a){var s=this.a
if((s.a&30)!==0)throw A.c(A.z("Future already completed"))
s.bf(a)},
L(){return this.U(null)},
ac(a){this.a.ac(a)}}
A.bg.prototype={
oi(a){var s
if((this.c&15)!==6)return!0
s=this.b.b
return s.dS(s,this.d,a.a,t.y,t.K)},
nL(a){var s,r=this.e,q=null,p=t.z,o=t.K,n=a.a,m=this.b.b
if(t.ng.b(r))q=m.ii(m,r,n,a.b,p,o,t.l)
else q=m.dS(m,r,n,p,o)
try{p=q
return p}catch(s){if(t.do.b(A.E(s))){if((this.c&1)!==0)throw A.c(A.H("The error handler of Future.then must return a value of the returned future's type","onError"))
throw A.c(A.H("The error handler of Future.catchError must return a value of the future's type","onError"))}else throw s}}}
A.l.prototype={
bc(a,b,c){var s,r,q=$.o
if(q===B.f){if(b!=null&&!t.ng.b(b)&&!t.mq.b(b))throw A.c(A.aZ(b,"onError",u.w))}else{a=q.c_(q,a,c.h("0/"),this.$ti.c)
if(b!=null)b=A.yn(b,q)}s=new A.l($.o,c.h("l<0>"))
r=b==null?1:3
this.cj(new A.bg(s,r,a,b,this.$ti.h("@<1>").I(c).h("bg<1,2>")))
return s},
aK(a,b){return this.bc(a,null,b)},
ir(a,b,c){var s=new A.l($.o,c.h("l<0>"))
this.cj(new A.bg(s,19,a,b,this.$ti.h("@<1>").I(c).h("bg<1,2>")))
return s},
lu(){var s,r
if(((this.a|=1)&4)!==0){s=this
do s=s.c
while(r=s.a,(r&4)!==0)
s.a=r|1}},
iN(a){var s=this.$ti,r=$.o,q=new A.l(r,s)
if(r!==B.f)a=A.yn(a,r)
this.cj(new A.bg(q,2,null,a,s.h("bg<1,1>")))
return q},
J(a){var s=this.$ti,r=$.o,q=new A.l(r,s)
if(r!==B.f)a=r.b4(r,a,t.z)
this.cj(new A.bg(q,8,a,null,s.h("bg<1,1>")))
return q},
mf(a){this.a=this.a&1|16
this.c=a},
dH(a){this.a=a.a&30|this.a&1
this.c=a.c},
cj(a){var s=this,r=s.a
if(r<=3){a.a=s.c
s.c=a}else{if((r&4)!==0){r=s.c
if((r.a&24)===0){r.cj(a)
return}s.dH(r)}r=s.b
r.bD(r,new A.rz(s,a))}},
i7(a){var s,r,q,p,o,n=this,m={}
m.a=a
if(a==null)return
s=n.a
if(s<=3){r=n.c
n.c=a
if(r!=null){q=a.a
for(p=a;q!=null;p=q,q=o)o=q.a
p.a=r}}else{if((s&4)!==0){s=n.c
if((s.a&24)===0){s.i7(a)
return}n.dH(s)}m.a=n.dR(a)
s=n.b
s.bD(s,new A.rE(m,n))}},
cX(){var s=this.c
this.c=null
return this.dR(s)},
dR(a){var s,r,q
for(s=a,r=null;s!=null;r=s,s=q){q=s.a
s.a=r}return r},
bf(a){var s,r=this
if(r.$ti.h("n<1>").b(a))A.rC(a,r,!0)
else{s=r.cX()
r.a=8
r.c=a
A.ds(r,s)}},
bT(a){var s=this,r=s.cX()
s.a=8
s.c=a
A.ds(s,r)},
l5(a){var s,r=this
if((a.a&16)!==0&&r.b.ax!=a.b.ax)return
s=r.cX()
r.dH(a)
A.ds(r,s)},
ac(a){var s=this.cX()
this.mf(a)
A.ds(this,s)},
l4(a,b){this.ac(new A.a2(a,b))},
aD(a){if(this.$ti.h("n<1>").b(a)){this.hw(a)
return}this.hu(a)},
hu(a){var s
this.a^=2
s=this.b
s.bD(s,new A.rB(this,a))},
hw(a){A.rC(a,this,!1)
return},
T(a){var s
this.a^=2
s=this.b
s.bD(s,new A.rA(this,a))},
oH(a,b){var s,r,q,p=this,o={}
if((p.a&24)!==0){o=new A.l($.o,p.$ti)
o.aD(p)
return o}s=p.$ti
r=$.o
q=new A.l(r,s)
o.a=null
if(b==null)o.a=A.jq(a,new A.rK(q,a))
else o.a=A.jq(a,new A.rL(p,q,r,r.b4(r,b,s.h("1/"))))
p.bc(new A.rM(o,p,q),new A.rN(o,q),t.P)
return q},
$in:1}
A.rz.prototype={
$0(){A.ds(this.a,this.b)},
$S:0}
A.rE.prototype={
$0(){A.ds(this.b,this.a.a)},
$S:0}
A.rD.prototype={
$0(){A.rC(this.a.a,this.b,!0)},
$S:0}
A.rB.prototype={
$0(){this.a.bT(this.b)},
$S:0}
A.rA.prototype={
$0(){this.a.ac(this.b)},
$S:0}
A.rH.prototype={
$0(){var s,r,q,p,o,n,m,l,k=this,j=null
try{q=k.a.a
p=q.b.b
j=p.c2(p,q.d,t.z)}catch(o){s=A.E(o)
r=A.M(o)
if(k.c&&k.b.a.c.a===s){q=k.a
q.c=k.b.a.c}else{q=s
p=r
if(p==null)p=A.cj(q)
n=k.a
n.c=new A.a2(q,p)
q=n}q.b=!0
return}if(j instanceof A.l&&(j.a&24)!==0){if((j.a&16)!==0){q=k.a
q.c=j.c
q.b=!0}return}if(j instanceof A.l){m=k.b.a
l=new A.l(m.b,m.$ti)
j.bc(new A.rI(l,m),new A.rJ(l),t.H)
q=k.a
q.c=l
q.b=!1}},
$S:0}
A.rI.prototype={
$1(a){this.a.l5(this.b)},
$S:11}
A.rJ.prototype={
$2(a,b){this.a.ac(new A.a2(a,b))},
$S:7}
A.rG.prototype={
$0(){var s,r,q,p,o,n,m
try{q=this.a
p=q.a
o=p.b.b
n=p.$ti
q.c=o.dS(o,p.d,this.b,n.h("2/"),n.c)}catch(m){s=A.E(m)
r=A.M(m)
q=s
p=r
if(p==null)p=A.cj(q)
o=this.a
o.c=new A.a2(q,p)
o.b=!0}},
$S:0}
A.rF.prototype={
$0(){var s,r,q,p,o,n,m,l=this
try{s=l.a.a.c
p=l.b
if(p.a.oi(s)&&p.a.e!=null){p.c=p.a.nL(s)
p.b=!1}}catch(o){r=A.E(o)
q=A.M(o)
p=l.a.a.c
if(p.a===r){n=l.b
n.c=p
p=n}else{p=r
n=q
if(n==null)n=A.cj(p)
m=l.b
m.c=new A.a2(p,n)
p=m}p.b=!0}},
$S:0}
A.rK.prototype={
$0(){var s=A.ec()
this.a.ac(new A.a2(new A.jp("Future not completed",this.b),s))},
$S:0}
A.rL.prototype={
$0(){var s,r,q,p,o,n=this
try{q=n.c
n.b.bf(q.c2(q,n.d,n.a.$ti.h("1/")))}catch(p){s=A.E(p)
r=A.M(p)
q=s
o=r
if(o==null)o=A.cj(q)
n.b.ac(new A.a2(q,o))}},
$S:0}
A.rM.prototype={
$1(a){var s=this.a.a
if(s.b!=null){s.u()
this.c.bT(a)}},
$S(){return this.b.$ti.h("D(1)")}}
A.rN.prototype={
$2(a,b){var s=this.a.a
if(s.b!=null){s.u()
this.b.ac(new A.a2(a,b))}},
$S:7}
A.jJ.prototype={}
A.C.prototype={
gaw(){return!1},
mK(a,b){var s,r=null,q={}
q.a=null
s=this.gaw()?q.a=new A.dw(r,r,b.h("dw<0>")):q.a=new A.cG(r,r,r,r,b.h("cG<0>"))
s.sjj(new A.oM(q,this,a))
return q.a.gbA()},
nE(a,b,c,d){var s,r={},q=new A.l($.o,d.h("l<0>"))
r.a=b
s=this.B(null,!0,new A.oR(r,q),q.gf0())
s.bt(new A.oS(r,this,c,s,q,d))
return q},
gk(a){var s={},r=new A.l($.o,t.hy)
s.a=0
this.B(new A.oT(s,this),!0,new A.oU(s,r),r.gf0())
return r},
gai(a){var s=new A.l($.o,A.p(this).h("l<C.T>")),r=this.B(null,!0,new A.oN(s),s.gf0())
r.bt(new A.oO(this,r,s))
return s}}
A.oM.prototype={
$0(){var s=this.b,r=this.a,q=r.a.gdG(),p=s.az(null,r.a.gaG(),q)
p.bt(new A.oL(r,s,this.c,p))
r.a.sji(p.ge5())
if(!s.gaw()){s=r.a
s.sjk(p.gep())
s.sjl(p.gbM())}},
$S:0}
A.oL.prototype={
$1(a){var s,r,q,p,o,n,m,l=this,k=null
try{k=l.c.$1(a)}catch(p){s=A.E(p)
r=A.M(p)
o=s
n=r
m=A.dA(o,n)
if(m==null)m=new A.a2(o,n==null?A.cj(o):n)
q=m
l.a.a.ag(q.a,q.b)
return}if(k!=null){o=l.d
o.aj()
l.a.a.iD(k).J(o.gbM())}},
$S(){return A.p(this.b).h("~(C.T)")}}
A.oR.prototype={
$0(){this.b.bf(this.a.a)},
$S:0}
A.oS.prototype={
$1(a){var s=this,r=s.a,q=s.f
A.Dl(new A.oP(r,s.c,a,q),new A.oQ(r,q),A.CD(s.d,s.e))},
$S(){return A.p(this.b).h("~(C.T)")}}
A.oP.prototype={
$0(){return this.b.$2(this.a.a,this.c)},
$S(){return this.d.h("0()")}}
A.oQ.prototype={
$1(a){this.a.a=a},
$S(){return this.b.h("D(0)")}}
A.oT.prototype={
$1(a){++this.a.a},
$S(){return A.p(this.b).h("~(C.T)")}}
A.oU.prototype={
$0(){this.b.bf(this.a.a)},
$S:0}
A.oN.prototype={
$0(){var s,r=A.ec(),q=new A.aW("No element")
A.iZ(q,r)
s=A.dA(q,r)
if(s==null)s=new A.a2(q,r)
this.a.ac(s)},
$S:0}
A.oO.prototype={
$1(a){A.CE(this.b,this.c,a)},
$S(){return A.p(this.a).h("~(C.T)")}}
A.fK.prototype={
gaw(){return this.a.gaw()},
B(a,b,c,d){return this.a.B(a,b,c,d)},
O(a){return this.B(a,null,null,null)},
az(a,b,c){return this.B(a,null,b,c)},
bq(a,b,c){return this.B(a,b,c,null)}}
A.jk.prototype={}
A.cE.prototype={
gbA(){return new A.a4(this,A.p(this).h("a4<1>"))},
glS(){if((this.b&8)===0)return this.a
return this.a.c},
bV(){var s,r,q=this
if((q.b&8)===0){s=q.a
return s==null?q.a=new A.eD():s}r=q.a
s=r.c
return s==null?r.c=new A.eD():s},
ga6(){var s=this.a
return(this.b&8)!==0?s.c:s},
aq(){if((this.b&4)!==0)return new A.aW("Cannot add event after closing")
return new A.aW("Cannot add event while adding a stream")},
e1(a,b){var s,r,q,p=this,o=p.b
if(o>=4)throw A.c(p.aq())
if((o&2)!==0){o=new A.l($.o,t._)
o.aD(null)
return o}o=p.a
s=b===!0
r=new A.l($.o,t._)
q=s?A.Bq(p):p.gdG()
q=a.B(p.geQ(),s,p.geW(),q)
s=p.b
if((s&1)!==0?(p.ga6().e&4)!==0:(s&2)===0)q.aj()
p.a=new A.ks(o,r,q)
p.b|=8
return r},
iD(a){return this.e1(a,null)},
dK(){var s=this.c
if(s==null)s=this.c=(this.b&2)!==0?$.cM():new A.l($.o,t.D)
return s},
q(a,b){if(this.b>=4)throw A.c(this.aq())
this.N(b)},
ag(a,b){var s
if(this.b>=4)throw A.c(this.aq())
s=A.aw(a,b)
this.ab(s.a,s.b)},
mE(a){return this.ag(a,null)},
n(){var s=this,r=s.b
if((r&4)!==0)return s.dK()
if(r>=4)throw A.c(s.aq())
s.hy()
return s.dK()},
hy(){var s=this.b|=4
if((s&1)!==0)this.bE()
else if((s&3)===0)this.bV().q(0,B.y)},
N(a){var s=this.b
if((s&1)!==0)this.a2(a)
else if((s&3)===0)this.bV().q(0,new A.bv(a))},
ab(a,b){var s=this.b
if((s&1)!==0)this.bj(a,b)
else if((s&3)===0)this.bV().q(0,new A.es(a,b))},
a_(){var s=this.a
this.a=s.c
this.b&=4294967287
s.a.aD(null)},
fq(a,b,c,d){var s,r,q,p=this
if((p.b&3)!==0)throw A.c(A.z("Stream has already been listened to."))
s=A.BI(p,a,b,c,d,A.p(p).c)
r=p.glS()
if(((p.b|=1)&8)!==0){q=p.a
q.c=s
q.b.am()}else p.a=s
s.mg(r)
s.f9(new A.tn(p))
return s},
i9(a){var s,r,q,p,o,n,m,l=this,k=null
if((l.b&8)!==0)k=l.a.u()
l.a=null
l.b=l.b&4294967286|2
s=l.r
if(s!=null)if(k==null)try{r=s.$0()
if(r instanceof A.l)k=r}catch(o){q=A.E(o)
p=A.M(o)
n=new A.l($.o,t.D)
n.T(new A.a2(q,p))
k=n}else k=k.J(s)
m=new A.tm(l)
if(k!=null)k=k.J(m)
else m.$0()
return k},
ia(a){if((this.b&8)!==0)this.a.b.aj()
A.kK(this.e)},
ib(a){if((this.b&8)!==0)this.a.b.am()
A.kK(this.f)},
$iah:1,
$ibG:1,
sjj(a){return this.d=a},
sjk(a){return this.e=a},
sjl(a){return this.f=a},
sji(a){return this.r=a}}
A.tn.prototype={
$0(){A.kK(this.a.d)},
$S:0}
A.tm.prototype={
$0(){var s=this.a.c
if(s!=null&&(s.a&30)===0)s.aD(null)},
$S:0}
A.kw.prototype={
a2(a){this.ga6().N(a)},
bj(a,b){this.ga6().ab(a,b)},
bE(){this.ga6().a_()}}
A.jL.prototype={
a2(a){this.ga6().be(new A.bv(a))},
bj(a,b){this.ga6().be(new A.es(a,b))},
bE(){this.ga6().be(B.y)}}
A.bK.prototype={}
A.cG.prototype={}
A.a4.prototype={
gv(a){return(A.e3(this.a)^892482866)>>>0},
D(a,b){if(b==null)return!1
if(this===b)return!0
return b instanceof A.a4&&b.a===this.a}}
A.cD.prototype={
dP(){return this.w.i9(this)},
b2(){this.w.ia(this)},
b3(){this.w.ib(this)}}
A.fZ.prototype={
u(){var s=this.b.u()
return s.J(new A.qC(this))}}
A.qD.prototype={
$2(a,b){var s=this.a
s.ab(a,b)
s.a_()},
$S:7}
A.qC.prototype={
$0(){this.a.a.aD(null)},
$S:1}
A.ks.prototype={}
A.av.prototype={
mg(a){var s=this
if(a==null)return
s.r=a
if(a.c!=null){s.e=(s.e|128)>>>0
a.dB(s)}},
bt(a){this.a=A.jN(this.d,a,A.p(this).h("av.T"))},
dk(a){var s=this,r=s.e
if(a==null)s.e=(r&4294967263)>>>0
else s.e=(r|32)>>>0
s.b=A.jO(s.d,a)},
aJ(a){var s,r=this,q=r.e
if((q&8)!==0)return
r.e=(q+256|4)>>>0
if(a!=null)a.J(r.gbM())
if(q<256){s=r.r
if(s!=null)if(s.a===1)s.a=3}if((q&4)===0&&(r.e&64)===0)r.f9(r.gcT())},
aj(){return this.aJ(null)},
am(){var s=this,r=s.e
if((r&8)!==0)return
if(r>=256){r=s.e=r-256
if(r<256)if((r&128)!==0&&s.r.c!=null)s.r.dB(s)
else{r=(r&4294967291)>>>0
s.e=r
if((r&64)===0)s.f9(s.gcU())}}},
u(){var s=this,r=(s.e&4294967279)>>>0
s.e=r
if((r&8)===0)s.eT()
r=s.f
return r==null?$.cM():r},
eT(){var s,r=this,q=r.e=(r.e|8)>>>0
if((q&128)!==0){s=r.r
if(s.a===1)s.a=3}if((q&64)===0)r.r=null
r.f=r.dP()},
N(a){var s=this.e
if((s&8)!==0)return
if(s<64)this.a2(a)
else this.be(new A.bv(a))},
ab(a,b){var s
if(t.C.b(a))A.iZ(a,b)
s=this.e
if((s&8)!==0)return
if(s<64)this.bj(a,b)
else this.be(new A.es(a,b))},
a_(){var s=this,r=s.e
if((r&8)!==0)return
r=(r|2)>>>0
s.e=r
if(r<64)s.bE()
else s.be(B.y)},
b2(){},
b3(){},
dP(){return null},
be(a){var s,r=this,q=r.r
if(q==null)q=r.r=new A.eD()
q.q(0,a)
s=r.e
if((s&128)===0){s=(s|128)>>>0
r.e=s
if(s<256)q.dB(r)}},
a2(a){var s=this,r=s.e
s.e=(r|64)>>>0
s.d.dt(s.a,a,A.p(s).h("av.T"))
s.e=(s.e&4294967231)>>>0
s.eV((r&4)!==0)},
bj(a,b){var s,r=this,q=r.e,p=new A.qY(r,a,b)
if((q&1)!==0){r.e=(q|16)>>>0
r.eT()
s=r.f
if(s!=null&&s!==$.cM())s.J(p)
else p.$0()}else{p.$0()
r.eV((q&4)!==0)}},
bE(){var s,r=this,q=new A.qX(r)
r.eT()
r.e=(r.e|16)>>>0
s=r.f
if(s!=null&&s!==$.cM())s.J(q)
else q.$0()},
f9(a){var s=this,r=s.e
s.e=(r|64)>>>0
a.$0()
s.e=(s.e&4294967231)>>>0
s.eV((r&4)!==0)},
eV(a){var s,r,q=this,p=q.e
if((p&128)!==0&&q.r.c==null){p=q.e=(p&4294967167)>>>0
s=!1
if((p&4)!==0)if(p<256){s=q.r
s=s==null?null:s.c==null
s=s!==!1}if(s){p=(p&4294967291)>>>0
q.e=p}}for(;;a=r){if((p&8)!==0){q.r=null
return}r=(p&4)!==0
if(a===r)break
q.e=(p^64)>>>0
if(r)q.b2()
else q.b3()
p=(q.e&4294967231)>>>0
q.e=p}if((p&128)!==0&&p<256)q.r.dB(q)},
$iac:1}
A.qY.prototype={
$0(){var s,r,q,p=this.a,o=p.e
if((o&8)!==0&&(o&16)===0)return
p.e=(o|64)>>>0
s=p.b
o=this.b
r=t.K
q=p.d
if(t.r.b(s))q.jw(s,o,this.c,r,t.l)
else q.dt(s,o,r)
p.e=(p.e&4294967231)>>>0},
$S:0}
A.qX.prototype={
$0(){var s=this.a,r=s.e
if((r&16)===0)return
s.e=(r|74)>>>0
s.d.h4(s.c)
s.e=(s.e&4294967231)>>>0},
$S:0}
A.eH.prototype={
B(a,b,c,d){return this.a.fq(a,d,c,b===!0)},
O(a){return this.B(a,null,null,null)},
az(a,b,c){return this.B(a,null,b,c)},
bq(a,b,c){return this.B(a,b,c,null)}}
A.jU.prototype={
gbs(){return this.a},
sbs(a){return this.a=a}}
A.bv.prototype={
h2(a){a.a2(this.b)}}
A.es.prototype={
h2(a){a.bj(this.b,this.c)}}
A.ro.prototype={
h2(a){a.bE()},
gbs(){return null},
sbs(a){throw A.c(A.z("No events after a done."))}}
A.eD.prototype={
dB(a){var s=this,r=s.a
if(r===1)return
if(r>=1){s.a=1
return}A.kQ(new A.tb(s,a))
s.a=1},
q(a,b){var s=this,r=s.c
if(r==null)s.b=s.c=b
else{r.sbs(b)
s.c=b}}}
A.tb.prototype={
$0(){var s,r,q=this.a,p=q.a
q.a=0
if(p===3)return
s=q.b
r=s.gbs()
q.b=r
if(r==null)q.c=null
s.h2(this.b)},
$S:0}
A.et.prototype={
bt(a){},
dk(a){},
aJ(a){var s=this.a
if(s>=0){this.a=s+2
if(a!=null)a.J(this.gbM())}},
aj(){return this.aJ(null)},
am(){var s=this,r=s.a-2
if(r<0)return
if(r===0){s.a=1
A.kQ(s.gi4())}else s.a=r},
u(){this.a=-1
this.c=null
return $.cM()},
lR(){var s,r=this,q=r.a-1
if(q===0){r.a=-1
s=r.c
if(s!=null){r.c=null
r.b.h4(s)}}else r.a=q},
$iac:1}
A.bO.prototype={
gp(){if(this.c)return this.b
return null},
l(){var s,r=this,q=r.a
if(q!=null){if(r.c){s=new A.l($.o,t.B)
r.b=s
r.c=!1
q.am()
return s}throw A.c(A.z("Already waiting for next."))}return r.lv()},
lv(){var s,r,q=this,p=q.b
if(p!=null){s=new A.l($.o,t.B)
q.b=s
r=p.B(q.glJ(),!0,q.glL(),q.glN())
if(q.b!=null)q.a=r
return s}return $.z0()},
u(){var s=this,r=s.a,q=s.b
s.b=null
if(r!=null){s.a=null
if(!s.c)q.aD(!1)
else s.c=!1
return r.u()}return $.cM()},
lK(a){var s,r,q=this
if(q.a==null)return
s=q.b
q.b=a
q.c=!0
s.bf(!0)
if(q.c){r=q.a
if(r!=null)r.aj()}},
lO(a,b){var s=this,r=s.a,q=s.b
s.b=s.a=null
if(r!=null)q.ac(new A.a2(a,b))
else q.T(new A.a2(a,b))},
lM(){var s=this,r=s.a,q=s.b
s.b=s.a=null
if(r!=null)q.bT(!1)
else q.hu(!1)}}
A.dr.prototype={
B(a,b,c,d){return A.xA(c,this.$ti.c)},
O(a){return this.B(a,null,null,null)},
az(a,b,c){return this.B(a,null,b,c)},
bq(a,b,c){return this.B(a,b,c,null)},
gaw(){return!0}}
A.bx.prototype={
B(a,b,c,d){var s=null,r=new A.hg(s,s,s,s,this.$ti.h("hg<1>"))
r.d=new A.t9(this,r)
return r.fq(a,d,c,b===!0)},
O(a){return this.B(a,null,null,null)},
az(a,b,c){return this.B(a,null,b,c)},
bq(a,b,c){return this.B(a,b,c,null)},
gaw(){return this.a}}
A.t9.prototype={
$0(){this.a.b.$1(this.b)},
$S:0}
A.hg.prototype={
mI(a){var s=this.b
if(s>=4)throw A.c(this.aq())
if((s&1)!==0)this.ga6().N(a)},
mF(a,b){var s=this.b
if(s>=4)throw A.c(this.aq())
if((s&1)!==0){s=this.ga6()
s.ab(a,b==null?B.t:b)}},
iP(){var s=this,r=s.b
if((r&4)!==0)return
if(r>=4)throw A.c(s.aq())
r|=4
s.b=r
if((r&1)!==0)s.ga6().a_()},
$ibZ:1}
A.tU.prototype={
$0(){return this.a.ac(this.b)},
$S:0}
A.tT.prototype={
$2(a,b){A.CC(this.a,this.b,new A.a2(a,b))},
$S:6}
A.tV.prototype={
$0(){return this.a.bf(this.b)},
$S:0}
A.b8.prototype={
gaw(){return this.a.gaw()},
B(a,b,c,d){var s=A.p(this),r=$.o,q=b===!0?1:0,p=d!=null?32:0,o=A.jN(r,a,s.h("b8.T")),n=A.jO(r,d),m=c==null?A.uj():c
s=new A.ex(this,o,n,r.b4(r,m,t.H),r,q|p,s.h("ex<b8.S,b8.T>"))
s.x=this.a.az(s.gfa(),s.gfc(),s.gfe())
return s},
O(a){return this.B(a,null,null,null)},
az(a,b,c){return this.B(a,null,b,c)},
bq(a,b,c){return this.B(a,b,c,null)}}
A.ex.prototype={
N(a){if((this.e&2)!==0)return
this.bR(a)},
ab(a,b){if((this.e&2)!==0)return
this.eN(a,b)},
b2(){var s=this.x
if(s!=null)s.aj()},
b3(){var s=this.x
if(s!=null)s.am()},
dP(){var s=this.x
if(s!=null){this.x=null
return s.u()}return null},
fb(a){this.w.hX(a,this)},
ff(a,b){this.ab(a,b)},
fd(){this.a_()}}
A.cf.prototype={
hX(a,b){var s,r,q,p=null
try{p=this.b.$1(a)}catch(q){s=A.E(q)
r=A.M(q)
A.y5(b,s,r)
return}if(p)b.N(a)}}
A.aL.prototype={
hX(a,b){var s,r,q,p=null
try{p=this.b.$1(a)}catch(q){s=A.E(q)
r=A.M(q)
A.y5(b,s,r)
return}b.N(p)}}
A.h9.prototype={
q(a,b){var s=this.a
if((s.e&2)!==0)A.r(A.z("Stream is already closed"))
s.bR(b)},
ag(a,b){var s=b==null?A.cj(a):b
this.a.ab(a,s)},
n(){var s=this.a
if((s.e&2)!==0)A.r(A.z("Stream is already closed"))
s.ho()},
$iah:1}
A.eF.prototype={
N(a){if((this.e&2)!==0)throw A.c(A.z("Stream is already closed"))
this.bR(a)},
ab(a,b){if((this.e&2)!==0)throw A.c(A.z("Stream is already closed"))
this.eN(a,b)},
a_(){if((this.e&2)!==0)throw A.c(A.z("Stream is already closed"))
this.ho()},
b2(){var s=this.x
if(s!=null)s.aj()},
b3(){var s=this.x
if(s!=null)s.am()},
dP(){var s=this.x
if(s!=null){this.x=null
return s.u()}return null},
fb(a){var s,r,q,p
try{q=this.w
q===$&&A.P()
q.q(0,a)}catch(p){s=A.E(p)
r=A.M(p)
this.ab(s,r)}},
ff(a,b){var s,r,q,p
try{q=this.w
q===$&&A.P()
q.ag(a,b)}catch(p){s=A.E(p)
r=A.M(p)
if(s===a)this.ab(a,b)
else this.ab(s,r)}},
fd(){var s,r,q,p
try{this.x=null
q=this.w
q===$&&A.P()
q.n()}catch(p){s=A.E(p)
r=A.M(p)
this.ab(s,r)}}}
A.c9.prototype={
gaw(){return this.b.gaw()},
B(a,b,c,d){var s=this.$ti,r=$.o,q=b===!0?1:0,p=d!=null?32:0,o=A.jN(r,a,s.y[1]),n=A.jO(r,d),m=c==null?A.uj():c,l=new A.eF(o,n,r.b4(r,m,t.H),r,q|p,s.h("eF<1,2>"))
l.w=this.a.$1(new A.h9(l))
l.x=this.b.az(l.gfa(),l.gfc(),l.gfe())
return l},
O(a){return this.B(a,null,null,null)},
az(a,b,c){return this.B(a,null,b,c)},
bq(a,b,c){return this.B(a,b,c,null)}}
A.kr.prototype={
bk(a){return this.a.$1(a)}}
A.tM.prototype={}
A.tL.prototype={}
A.tN.prototype={}
A.c8.prototype={
oC(a,b){return this.c2(this,a,b)},
h4(a){var s,r,q,p,o=this
try{q=o.c2(o,a,t.H)
return q}catch(p){s=A.E(p)
r=A.M(p)
o.b1(o,s,r)}},
dt(a,b,c){var s,r,q,p,o=this
try{q=o.dS(o,a,b,t.H,c)
return q}catch(p){s=A.E(p)
r=A.M(p)
o.b1(o,s,r)}},
jw(a,b,c,d,e){var s,r,q,p,o=this
try{q=o.ii(o,a,b,c,t.H,d,e)
return q}catch(p){s=A.E(p)
r=A.M(p)
o.b1(o,s,r)}},
iJ(a,b){return new A.qs(this,this.b4(this,a,b),b)},
e4(a){return new A.qr(this,this.b4(this,a,t.H))},
iK(a,b){return new A.qt(this,this.c_(this,a,t.H,b),b)},
i(a,b){var s,r,q,p=this.ay
while(p!=null){s=p.b
r=s.i(0,b)
if(r!=null||s.F(b))return r
q=p.a.a
p=q==null?null:q.ay}return null},
gaU(){var s=this.a
s=s==null?null:s.b
return s==null?$.zs():s},
b1(a,b,c){var s,r,q,p,o,n,m,l=this.ax
if(l==null){A.Dk(b,c)
return}s=l.a
n=s.a
n.toString
r=n
q=$.o
try{$.o=r
n=s.gaU()
l.b.$5(s,n,a,b,c)
$.o=q}catch(m){p=A.E(m)
o=A.M(m)
$.o=q
n=b===p?c:o
r.b1(s,p,n)}},
hQ(a,b,c){var s,r,q=this.at
if(q==null)return A.Dj(a,b,c)
s=q.a
r=s.gaU()
return q.b.$5(s,r,a,b,c)},
c2(a,b,c){var s,r,q,p=this.c
if(p==null){r=$.o
if(r===a)return b.$0()
s=r
$.o=a
try{r=b.$0()
return r}finally{$.o=s}}q=p.a
r=q.gaU()
return p.b.$1$4(q,r,a,b,c)},
dS(a,b,c,d,e){var s,r,q,p=this.d
if(p==null){r=$.o
if(r===a)return b.$1(c)
s=r
$.o=a
try{r=b.$1(c)
return r}finally{$.o=s}}q=p.a
r=q.gaU()
return p.b.$2$5(q,r,a,b,c,d,e)},
ii(a,b,c,d,e,f,g){var s,r,q,p=this.e
if(p==null){r=$.o
if(r===a)return b.$2(c,d)
s=r
$.o=a
try{r=b.$2(c,d)
return r}finally{$.o=s}}q=p.a
r=q.gaU()
return p.b.$3$6(q,r,a,b,c,d,e,f,g)},
b4(a,b,c){var s,r,q=this.f
if(q==null)return b
s=q.a
r=s.gaU()
return q.b.$1$4(s,r,a,b,c)},
c_(a,b,c,d){var s,r,q=this.r
if(q==null)return b
s=q.a
r=s.gaU()
return q.b.$2$4(s,r,a,b,c,d)},
cW(a,b,c,d,e){var s,r,q=this.w
if(q==null)return b
s=q.a
r=s.gaU()
return q.b.$3$4(s,r,a,b,c,d,e)},
lh(a,b,c){var s,r,q=this.x
if(q==null)return null
s=q.a
r=s.gaU()
return q.b.$5(s,r,a,b,c)},
bD(a,b){var s,r,q=this.y
if(q==null){A.vX(a,b)
return}s=q.a
r=s.gaU()
q.b.$4(s,r,a,b)},
hH(a,b,c){var s,r,q=this.z
if(q==null)return A.xk(b,B.f!==a?a.iJ(c,t.H):c)
s=q.a
r=s.gaU()
return q.b.$5(s,r,a,b,c)}}
A.qs.prototype={
$0(){var s=this.a
return s.c2(s,this.b,this.c)},
$S(){return this.c.h("0()")}}
A.qr.prototype={
$0(){return this.a.h4(this.b)},
$S:0}
A.qt.prototype={
$1(a){return this.a.dt(this.b,a,this.c)},
$S(){return this.c.h("~(0)")}}
A.dk.prototype={}
A.u5.prototype={
$0(){A.ik(this.a,this.b)},
$S:0}
A.qq.prototype={}
A.cc.prototype={
gk(a){return this.a},
gE(a){return this.a===0},
ga3(){return new A.hb(this,A.p(this).h("hb<1>"))},
F(a){var s,r
if(typeof a=="string"&&a!=="__proto__"){s=this.b
return s==null?!1:s[a]!=null}else if(typeof a=="number"&&(a&1073741823)===a){r=this.c
return r==null?!1:r[a]!=null}else return this.hF(a)},
hF(a){var s=this.d
if(s==null)return!1
return this.bg(this.hC(s,a),a)>=0},
a7(a,b){b.ad(0,new A.rO(this))},
i(a,b){var s,r,q
if(typeof b=="string"&&b!=="__proto__"){s=this.b
r=s==null?null:A.xD(s,b)
return r}else if(typeof b=="number"&&(b&1073741823)===b){q=this.c
r=q==null?null:A.xD(q,b)
return r}else return this.hT(b)},
hT(a){var s,r,q=this.d
if(q==null)return null
s=this.hC(q,a)
r=this.bg(s,a)
return r<0?null:s[r+1]},
m(a,b,c){var s,r,q=this
if(typeof b=="string"&&b!=="__proto__"){s=q.b
q.hA(s==null?q.b=A.vC():s,b,c)}else if(typeof b=="number"&&(b&1073741823)===b){r=q.c
q.hA(r==null?q.c=A.vC():r,b,c)}else q.ij(b,c)},
ij(a,b){var s,r,q,p=this,o=p.d
if(o==null)o=p.d=A.vC()
s=p.bB(a)
r=o[s]
if(r==null){A.vD(o,s,[a,b]);++p.a
p.e=null}else{q=p.bg(r,a)
if(q>=0)r[q+1]=b
else{r.push(a,b);++p.a
p.e=null}}},
ad(a,b){var s,r,q,p,o,n=this,m=n.hB()
for(s=m.length,r=A.p(n).y[1],q=0;q<s;++q){p=m[q]
o=n.i(0,p)
b.$2(p,o==null?r.a(o):o)
if(m!==n.e)throw A.c(A.am(n))}},
hB(){var s,r,q,p,o,n,m,l,k,j,i=this,h=i.e
if(h!=null)return h
h=A.b4(i.a,null,!1,t.z)
s=i.b
r=0
if(s!=null){q=Object.getOwnPropertyNames(s)
p=q.length
for(o=0;o<p;++o){h[r]=q[o];++r}}n=i.c
if(n!=null){q=Object.getOwnPropertyNames(n)
p=q.length
for(o=0;o<p;++o){h[r]=+q[o];++r}}m=i.d
if(m!=null){q=Object.getOwnPropertyNames(m)
p=q.length
for(o=0;o<p;++o){l=m[q[o]]
k=l.length
for(j=0;j<k;j+=2){h[r]=l[j];++r}}}return i.e=h},
hA(a,b,c){if(a[b]==null){++this.a
this.e=null}A.vD(a,b,c)},
bB(a){return J.U(a)&1073741823},
hC(a,b){return a[this.bB(b)]},
bg(a,b){var s,r
if(a==null)return-1
s=a.length
for(r=0;r<s;r+=2)if(J.A(a[r],b))return r
return-1}}
A.rO.prototype={
$2(a,b){this.a.m(0,a,b)},
$S(){return A.p(this.a).h("~(1,2)")}}
A.dt.prototype={
bB(a){return A.kP(a)&1073741823},
bg(a,b){var s,r,q
if(a==null)return-1
s=a.length
for(r=0;r<s;r+=2){q=a[r]
if(q==null?b==null:q===b)return r}return-1}}
A.h4.prototype={
i(a,b){if(!this.w.$1(b))return null
return this.kA(b)},
m(a,b,c){this.kB(b,c)},
F(a){if(!this.w.$1(a))return!1
return this.kz(a)},
bB(a){return this.r.$1(a)&1073741823},
bg(a,b){var s,r,q
if(a==null)return-1
s=a.length
for(r=this.f,q=0;q<s;q+=2)if(r.$2(a[q],b))return q
return-1}}
A.rk.prototype={
$1(a){return this.a.b(a)},
$S:17}
A.hb.prototype={
gk(a){return this.a.a},
gE(a){return this.a.a===0},
gaO(a){return this.a.a!==0},
gA(a){var s=this.a
return new A.k_(s,s.hB(),this.$ti.h("k_<1>"))},
V(a,b){return this.a.F(b)}}
A.k_.prototype={
gp(){var s=this.d
return s==null?this.$ti.c.a(s):s},
l(){var s=this,r=s.b,q=s.c,p=s.a
if(r!==p.e)throw A.c(A.am(p))
else if(q>=r.length){s.d=null
return!1}else{s.d=r[q]
s.c=q+1
return!0}}}
A.hf.prototype={
i(a,b){if(!this.y.$1(b))return null
return this.kq(b)},
m(a,b,c){this.ks(b,c)},
F(a){if(!this.y.$1(a))return!1
return this.kp(a)},
H(a,b){if(!this.y.$1(b))return null
return this.kr(b)},
di(a){return this.x.$1(a)&1073741823},
cv(a,b){var s,r,q
if(a==null)return-1
s=a.length
for(r=this.w,q=0;q<s;++q)if(r.$2(a[q].a,b))return q
return-1}}
A.t7.prototype={
$1(a){return this.a.b(a)},
$S:17}
A.cd.prototype={
lI(){return new A.cd(A.p(this).h("cd<1>"))},
gA(a){var s=this,r=new A.eA(s,s.r,A.p(s).h("eA<1>"))
r.c=s.e
return r},
gk(a){return this.a},
gE(a){return this.a===0},
gaO(a){return this.a!==0},
V(a,b){var s,r
if(b!=="__proto__"){s=this.b
if(s==null)return!1
return s[b]!=null}else{r=this.l8(b)
return r}},
l8(a){var s=this.d
if(s==null)return!1
return this.bg(s[this.bB(a)],a)>=0},
q(a,b){var s,r,q=this
if(typeof b=="string"&&b!=="__proto__"){s=q.b
return q.hz(s==null?q.b=A.vF():s,b)}else if(typeof b=="number"&&(b&1073741823)===b){r=q.c
return q.hz(r==null?q.c=A.vF():r,b)}else return q.l2(b)},
l2(a){var s,r,q=this,p=q.d
if(p==null)p=q.d=A.vF()
s=q.bB(a)
r=p[s]
if(r==null)p[s]=[q.eZ(a)]
else{if(q.bg(r,a)>=0)return!1
r.push(q.eZ(a))}return!0},
H(a,b){var s=this
if(typeof b=="string"&&b!=="__proto__")return s.hD(s.b,b)
else if(typeof b=="number"&&(b&1073741823)===b)return s.hD(s.c,b)
else return s.fo(b)},
fo(a){var s,r,q,p,o=this,n=o.d
if(n==null)return!1
s=o.bB(a)
r=n[s]
q=o.bg(r,a)
if(q<0)return!1
p=r.splice(q,1)[0]
if(0===r.length)delete n[s]
o.hE(p)
return!0},
aF(a){var s=this
if(s.a>0){s.b=s.c=s.d=s.e=s.f=null
s.a=0
s.eY()}},
hz(a,b){if(a[b]!=null)return!1
a[b]=this.eZ(b)
return!0},
hD(a,b){var s
if(a==null)return!1
s=a[b]
if(s==null)return!1
this.hE(s)
delete a[b]
return!0},
eY(){this.r=this.r+1&1073741823},
eZ(a){var s,r=this,q=new A.t8(a)
if(r.e==null)r.e=r.f=q
else{s=r.f
s.toString
q.c=s
r.f=s.b=q}++r.a
r.eY()
return q},
hE(a){var s=this,r=a.c,q=a.b
if(r==null)s.e=q
else r.b=q
if(q==null)s.f=r
else q.c=r;--s.a
s.eY()},
bB(a){return J.U(a)&1073741823},
bg(a,b){var s,r
if(a==null)return-1
s=a.length
for(r=0;r<s;++r)if(J.A(a[r].a,b))return r
return-1}}
A.t8.prototype={}
A.eA.prototype={
gp(){var s=this.d
return s==null?this.$ti.c.a(s):s},
l(){var s=this,r=s.c,q=s.a
if(s.b!==q.r)throw A.c(A.am(q))
else if(r==null){s.d=null
return!1}else{s.d=r.a
s.c=r.b
return!0}}}
A.nK.prototype={
$2(a,b){this.a.m(0,this.b.a(a),this.c.a(b))},
$S:91}
A.d3.prototype={
V(a,b){return!1},
gA(a){var s=this
return new A.k6(s,s.a,s.c,s.$ti.h("k6<1>"))},
gk(a){return this.b},
aF(a){var s,r,q,p=this;++p.a
if(p.b===0)return
s=p.c
s.toString
r=s
do{q=r.b
q.toString
r.b=r.c=r.a=null
if(q!==s){r=q
continue}else break}while(!0)
p.c=null
p.b=0},
gai(a){var s
if(this.b===0)throw A.c(A.z("No such element"))
s=this.c
s.toString
return s},
gaP(a){var s
if(this.b===0)throw A.c(A.z("No such element"))
s=this.c.c
s.toString
return s},
gE(a){return this.b===0},
dM(a,b,c){var s,r,q=this
if(b.a!=null)throw A.c(A.z("LinkedListEntry is already in a LinkedList"));++q.a
b.a=q
s=q.b
if(s===0){b.b=b
q.c=b.c=b
q.b=s+1
return}r=a.c
r.toString
b.c=r
b.b=a
a.c=r.b=b
q.b=s+1},
ft(a){var s,r,q=this;++q.a
s=a.b
s.c=a.c
a.c.b=s
r=--q.b
a.a=a.b=a.c=null
if(r===0)q.c=null
else if(a===q.c)q.c=s}}
A.k6.prototype={
gp(){var s=this.c
return s==null?this.$ti.c.a(s):s},
l(){var s=this,r=s.a
if(s.b!==r.a)throw A.c(A.am(s))
if(r.b!==0)r=s.e&&s.d===r.gai(0)
else r=!0
if(r){s.c=null
return!1}s.e=!0
r=s.d
s.c=r
s.d=r.b
return!0}}
A.aG.prototype={
gdm(){var s=this.a
if(s==null||this===s.gai(0))return null
return this.c}}
A.y.prototype={
gA(a){return new A.as(a,this.gk(a),A.ba(a).h("as<y.E>"))},
W(a,b){return this.i(a,b)},
gE(a){return this.gk(a)===0},
gaO(a){return!this.gE(a)},
gai(a){if(this.gk(a)===0)throw A.c(A.bW())
return this.i(a,0)},
V(a,b){var s,r=this.gk(a)
for(s=0;s<r;++s){if(J.A(this.i(a,s),b))return!0
if(r!==this.gk(a))throw A.c(A.am(a))}return!1},
ba(a,b,c){return new A.a8(a,b,A.ba(a).h("@<y.E>").I(c).h("a8<1,2>"))},
aT(a,b){return A.bJ(a,b,null,A.ba(a).h("y.E"))},
bN(a,b){return A.bJ(a,0,A.bA(b,"count",t.S),A.ba(a).h("y.E"))},
q(a,b){var s=this.gk(a)
this.sk(a,s+1)
this.m(a,s,b)},
e6(a,b){return new A.ae(a,A.ba(a).h("@<y.E>").I(b).h("ae<1,2>"))},
cM(a,b){var s=b==null?A.DI():b
A.j8(a,0,this.gk(a)-1,s)},
kb(a,b,c){A.aI(b,c,this.gk(a))
return A.bJ(a,b,c,A.ba(a).h("y.E"))},
fJ(a,b,c,d){var s,r=d==null?A.ba(a).h("y.E").a(d):d
A.aI(b,c,this.gk(a))
for(s=b;s<c;++s)this.m(a,s,r)},
Y(a,b,c,d,e){var s,r,q,p,o
A.aI(b,c,this.gk(a))
s=c-b
if(s===0)return
A.aH(e,"skipCount")
if(t.j.b(d)){r=e
q=d}else{q=J.kZ(d,e).ca(0,!1)
r=0}p=J.aa(q)
if(r+s>p.gk(q))throw A.c(A.wH())
if(r<b)for(o=s-1;o>=0;--o)this.m(a,b+o,p.i(q,r+o))
else for(o=0;o<s;++o)this.m(a,b+o,p.i(q,r+o))},
af(a,b,c,d){return this.Y(a,b,c,d,0)},
cJ(a,b,c){var s,r
if(t.j.b(c))this.af(a,b,b+c.length,c)
else for(s=J.a0(c);s.l();b=r){r=b+1
this.m(a,b,s.gp())}},
j(a){return A.nE(a,"[","]")},
$ix:1,
$im:1,
$it:1}
A.F.prototype={
bl(a,b,c){var s=A.p(this)
return A.wQ(this,s.h("F.K"),s.h("F.V"),b,c)},
ad(a,b){var s,r,q,p
for(s=J.a0(this.ga3()),r=A.p(this).h("F.V");s.l();){q=s.gp()
p=this.i(0,q)
b.$2(q,p==null?r.a(p):p)}},
gbm(){return J.dI(this.ga3(),new A.nO(this),A.p(this).h("K<F.K,F.V>"))},
cz(a,b,c,d){var s,r,q,p,o,n=A.T(c,d)
for(s=J.a0(this.ga3()),r=A.p(this).h("F.V");s.l();){q=s.gp()
p=this.i(0,q)
o=b.$2(q,p==null?r.a(p):p)
n.m(0,o.a,o.b)}return n},
F(a){return J.wh(this.ga3(),a)},
gk(a){return J.aM(this.ga3())},
gE(a){return J.kY(this.ga3())},
j(a){return A.nP(this)},
$ia3:1}
A.nO.prototype={
$1(a){var s=this.a,r=s.i(0,a)
if(r==null)r=A.p(s).h("F.V").a(r)
return new A.K(a,r,A.p(s).h("K<F.K,F.V>"))},
$S(){return A.p(this.a).h("K<F.K,F.V>(F.K)")}}
A.nQ.prototype={
$2(a,b){var s,r=this.a
if(!r.a)this.b.a+=", "
r.a=!1
r=this.b
s=A.q(a)
r.a=(r.a+=s)+": "
s=A.q(b)
r.a+=s},
$S:42}
A.kz.prototype={}
A.fu.prototype={
bl(a,b,c){return this.a.bl(0,b,c)},
i(a,b){return this.a.i(0,b)},
F(a){return this.a.F(a)},
ad(a,b){this.a.ad(0,b)},
gE(a){var s=this.a
return s.gE(s)},
gk(a){var s=this.a
return s.gk(s)},
ga3(){return this.a.ga3()},
j(a){return this.a.j(0)},
gbm(){return this.a.gbm()},
cz(a,b,c,d){return this.a.cz(0,b,c,d)},
$ia3:1}
A.dh.prototype={
bl(a,b,c){return new A.dh(this.a.bl(0,b,c),b.h("@<0>").I(c).h("dh<1,2>"))}}
A.fs.prototype={
gA(a){var s=this
return new A.k7(s,s.c,s.d,s.b,s.$ti.h("k7<1>"))},
gE(a){return this.b===this.c},
gk(a){return(this.c-this.b&this.a.length-1)>>>0},
W(a,b){var s,r=this
A.Ak(b,r.gk(0),r,null,null)
s=r.a
s=s[(r.b+b&s.length-1)>>>0]
return s==null?r.$ti.c.a(s):s},
H(a,b){var s,r=this
for(s=r.b;s!==r.c;s=(s+1&r.a.length-1)>>>0)if(J.A(r.a[s],b)){r.fo(s);++r.d
return!0}return!1},
j(a){return A.nE(this,"{","}")},
fo(a){var s,r,q,p=this,o=p.a,n=o.length-1,m=p.b,l=p.c
if((a-m&n)>>>0<(l-a&n)>>>0){for(s=a;s!==m;s=r){r=(s-1&n)>>>0
o[s]=o[r]}o[m]=null
p.b=(m+1&n)>>>0
return(a+1&n)>>>0}else{m=p.c=(l-1&n)>>>0
for(s=a;s!==m;s=q){q=(s+1&n)>>>0
o[s]=o[q]}o[m]=null
return a}}}
A.k7.prototype={
gp(){var s=this.e
return s==null?this.$ti.c.a(s):s},
l(){var s,r=this,q=r.a
if(r.c!==q.d)A.r(A.am(q))
s=r.d
if(s===r.b){r.e=null
return!1}q=q.a
r.e=q[s]
r.d=(s+1&q.length-1)>>>0
return!0}}
A.cw.prototype={
gE(a){return this.gk(this)===0},
gaO(a){return this.gk(this)!==0},
a7(a,b){var s
for(s=J.a0(b);s.l();)this.q(0,s.gp())},
cE(a){var s=this.du(0)
s.a7(0,a)
return s},
ba(a,b,c){return new A.bU(this,b,A.p(this).h("@<1>").I(c).h("bU<1,2>"))},
j(a){return A.nE(this,"{","}")},
bN(a,b){return A.xh(this,b,A.p(this).c)},
aT(a,b){return A.xa(this,b,A.p(this).c)},
W(a,b){var s,r
A.aH(b,"index")
s=this.gA(this)
for(r=b;s.l();){if(r===0)return s.gp();--r}throw A.c(A.it(b,b-r,this,null,"index"))},
$ix:1,
$im:1,
$ibs:1}
A.hs.prototype={
du(a){var s=this.lI()
s.a7(0,this)
return s}}
A.hB.prototype={}
A.k3.prototype={
i(a,b){var s,r=this.b
if(r==null)return this.c.i(0,b)
else if(typeof b!="string")return null
else{s=r[b]
return typeof s=="undefined"?this.lW(b):s}},
gk(a){return this.b==null?this.c.a:this.dI().length},
gE(a){return this.gk(0)===0},
ga3(){if(this.b==null){var s=this.c
return new A.b2(s,A.p(s).h("b2<1>"))}return new A.k4(this)},
F(a){if(this.b==null)return this.c.F(a)
return Object.prototype.hasOwnProperty.call(this.a,a)},
ad(a,b){var s,r,q,p,o=this
if(o.b==null)return o.c.ad(0,b)
s=o.dI()
for(r=0;r<s.length;++r){q=s[r]
p=o.b[q]
if(typeof p=="undefined"){p=A.tW(o.a[q])
o.b[q]=p}b.$2(q,p)
if(s!==o.c)throw A.c(A.am(o))}},
dI(){var s=this.c
if(s==null)s=this.c=A.u(Object.keys(this.a),t.s)
return s},
lW(a){var s
if(!Object.prototype.hasOwnProperty.call(this.a,a))return null
s=A.tW(this.a[a])
return this.b[a]=s}}
A.k4.prototype={
gk(a){return this.a.gk(0)},
W(a,b){var s=this.a
return s.b==null?s.ga3().W(0,b):s.dI()[b]},
gA(a){var s=this.a
if(s.b==null){s=s.ga3()
s=s.gA(s)}else{s=s.dI()
s=new J.dJ(s,s.length,A.a5(s).h("dJ<1>"))}return s},
V(a,b){return this.a.F(b)}}
A.t0.prototype={
n(){var s,r,q=this
q.kC()
s=q.a
r=s.a
s.a=""
s=q.c.a
s.N(A.yk(r.charCodeAt(0)==0?r:r,q.b))
s.a_()}}
A.tH.prototype={
$0(){var s,r
try{s=new TextDecoder("utf-8",{fatal:true})
return s}catch(r){}return null},
$S:44}
A.tG.prototype={
$0(){var s,r
try{s=new TextDecoder("utf-8",{fatal:false})
return s}catch(r){}return null},
$S:44}
A.hR.prototype={
gbK(){return"us-ascii"},
b9(a){return B.aJ.av(a)},
aI(a){var s=B.a0.av(a)
return s},
gd6(){return B.a0}}
A.ky.prototype={
av(a){var s,r,q,p=A.aI(0,null,a.length),o=new Uint8Array(p)
for(s=~this.a,r=0;r<p;++r){q=a.charCodeAt(r)
if((q&s)!==0)throw A.c(A.aZ(a,"string","Contains invalid characters."))
o[r]=q}return o},
bd(a){return new A.tz(new A.jP(a),this.a)}}
A.hT.prototype={}
A.tz.prototype={
n(){this.a.a.a.a_()},
ae(a,b,c,d){var s,r,q,p,o
A.aI(b,c,a.length)
for(s=~this.b,r=b;r<c;++r){q=a.charCodeAt(r)
if((q&s)!==0)throw A.c(A.H("Source contains invalid character with code point: "+q+".",null))}s=new A.bn(a)
p=s.gk(0)
A.aI(b,c,p)
s=A.an(s.kb(s,b,c),t.V.h("y.E"))
o=this.a.a.a
o.N(s)
if(d)o.a_()}}
A.kx.prototype={
av(a){var s,r,q,p=A.aI(0,null,a.length)
for(s=~this.b,r=0;r<p;++r){q=a[r]
if((q&s)!==0){if(!this.a)throw A.c(A.ai("Invalid value in input: "+q,null,null))
return this.l9(a,0,p)}}return A.bI(a,0,p)},
l9(a,b,c){var s,r,q,p
for(s=~this.b,r=b,q="";r<c;++r){p=a[r]
q+=A.aQ((p&s)!==0?65533:p)}return q.charCodeAt(0)==0?q:q},
bk(a){return this.hm(a)}}
A.hS.prototype={
bd(a){var s=new A.dv(a)
if(this.a)return new A.rr(new A.kB(new A.cI(!1),s,new A.Z("")))
else return new A.te(s)}}
A.rr.prototype={
n(){this.a.n()},
q(a,b){this.ae(b,0,J.aM(b),!1)},
ae(a,b,c,d){var s,r,q=J.aa(a)
A.aI(b,c,q.gk(a))
for(s=this.a,r=b;r<c;++r)if((q.i(a,r)&4294967168)>>>0!==0){if(r>b)s.ae(a,b,r,!1)
s.ae(B.bp,0,3,!1)
b=r+1}if(b<c)s.ae(a,b,c,!1)}}
A.te.prototype={
n(){this.a.a.a.a_()},
q(a,b){var s,r
for(s=J.aa(b),r=0;r<s.gk(b);++r)if((s.i(b,r)&4294967168)>>>0!==0)throw A.c(A.ai("Source contains non-ASCII bytes.",null,null))
this.a.a.a.N(A.bI(b,0,null))}}
A.ld.prototype={
oj(a0,a1,a2){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a="Invalid base64 encoding length "
a2=A.aI(a1,a2,a0.length)
s=$.zd()
for(r=a1,q=r,p=null,o=-1,n=-1,m=0;r<a2;r=l){l=r+1
k=a0.charCodeAt(r)
if(k===37){j=l+2
if(j<=a2){i=A.uw(a0.charCodeAt(l))
h=A.uw(a0.charCodeAt(l+1))
g=i*16+h-(h&256)
if(g===37)g=-1
l=j}else g=-1}else g=k
if(0<=g&&g<=127){f=s[g]
if(f>=0){g=u.U.charCodeAt(f)
if(g===k)continue
k=g}else{if(f===-1){if(o<0){e=p==null?null:p.a.length
if(e==null)e=0
o=e+(r-q)
n=r}++m
if(k===61)continue}k=g}if(f!==-2){if(p==null){p=new A.Z("")
e=p}else e=p
e.a+=B.a.t(a0,q,r)
d=A.aQ(k)
e.a+=d
q=l
continue}}throw A.c(A.ai("Invalid base64 data",a0,r))}if(p!=null){e=B.a.t(a0,q,a2)
e=p.a+=e
d=e.length
if(o>=0)A.wl(a0,n,a2,o,m,d)
else{c=B.b.aS(d-1,4)+1
if(c===1)throw A.c(A.ai(a,a0,a2))
while(c<4){e+="="
p.a=e;++c}}e=p.a
return B.a.c9(a0,a1,a2,e.charCodeAt(0)==0?e:e)}b=a2-a1
if(o>=0)A.wl(a0,n,a2,o,m,b)
else{c=B.b.aS(b,4)
if(c===1)throw A.c(A.ai(a,a0,a2))
if(c>1)a0=B.a.c9(a0,a2,a2,c===2?"==":"=")}return a0}}
A.hX.prototype={
bd(a){return new A.qE(a,new A.qW(u.U))}}
A.qP.prototype={
iR(a){return new Uint8Array(a)},
np(a,b,c,d){var s,r=this,q=(r.a&3)+(c-b),p=B.b.R(q,3),o=p*4
if(d&&q-p*3>0)o+=4
s=r.iR(o)
r.a=A.Bw(r.b,a,b,c,d,s,0,r.a)
if(o>0)return s
return null}}
A.qW.prototype={
iR(a){var s=this.c
if(s==null||s.length<a)s=this.c=new Uint8Array(a)
return J.cO(B.e.gau(s),s.byteOffset,a)}}
A.qQ.prototype={
q(a,b){this.hG(b,0,J.aM(b),!1)},
n(){this.hG(B.bu,0,0,!0)}}
A.qE.prototype={
hG(a,b,c,d){var s=this.b.np(a,b,c,d)
if(s!=null)this.a.a.N(A.bI(s,0,null))
if(d)this.a.a.a_()}}
A.lu.prototype={}
A.jP.prototype={
q(a,b){this.a.a.N(b)},
n(){this.a.a.a_()}}
A.jQ.prototype={
q(a,b){var s,r,q=this,p=q.b,o=q.c,n=J.aa(b)
if(n.gk(b)>p.length-o){p=q.b
s=n.gk(b)+p.length-1
s|=B.b.Z(s,1)
s|=s>>>2
s|=s>>>4
s|=s>>>8
r=new Uint8Array((((s|s>>>16)>>>0)+1)*2)
p=q.b
B.e.af(r,0,p.length,p)
q.b=r}p=q.b
o=q.c
B.e.af(p,o,o+n.gk(b),b)
q.c=q.c+n.gk(b)},
n(){this.a.$1(B.e.bQ(this.b,0,this.c))}}
A.i7.prototype={}
A.dp.prototype={
q(a,b){this.b.q(0,b)},
ag(a,b){A.bA(a,"error",t.K)
this.a.ag(a,b)},
n(){this.b.n()},
$iah:1}
A.i8.prototype={}
A.af.prototype={
bd(a){throw A.c(A.R("This converter does not support chunked conversions: "+this.j(0)))},
bk(a){return new A.c9(new A.m0(this),a,t.fM.I(A.p(this).h("af.T")).h("c9<1,2>"))}}
A.m0.prototype={
$1(a){return new A.dp(a,this.a.bd(a))},
$S:108}
A.cZ.prototype={
mW(a){return this.gd6().bk(a).nE(0,new A.Z(""),new A.mQ(),t.of).aK(new A.mR(),t.N)}}
A.mQ.prototype={
$2(a,b){a.a+=b
return a},
$S:111}
A.mR.prototype={
$1(a){var s=a.a
return s.charCodeAt(0)==0?s:s},
$S:123}
A.fq.prototype={
j(a){var s=A.ij(this.a)
return(this.b!=null?"Converting object to an encodable object failed:":"Converting object did not return an encodable object:")+" "+s}}
A.iA.prototype={
j(a){return"Cyclic error in JSON stringify"}}
A.nH.prototype={
c5(a,b){var s=A.yk(a,this.gd6().a)
return s},
aI(a){return this.c5(a,null)},
fH(a,b){var s=A.BS(a,this.gnq().b,null)
return s},
b9(a){return this.fH(a,null)},
gnq(){return B.bm},
gd6(){return B.bl}}
A.iC.prototype={
bd(a){return new A.t1(null,this.b,new A.dv(a))}}
A.t1.prototype={
q(a,b){var s,r,q,p=this
if(p.d)throw A.c(A.z("Only one call to add allowed"))
p.d=!0
s=p.c
r=new A.Z("")
q=new A.ts(r,s)
A.xG(b,q,p.b,p.a)
if(r.a.length!==0)q.f6()
s.n()},
n(){}}
A.iB.prototype={
bd(a){return new A.t0(this.a,a,new A.Z(""))}}
A.t3.prototype={
jC(a){var s,r,q,p,o,n=this,m=a.length
for(s=0,r=0;r<m;++r){q=a.charCodeAt(r)
if(q>92){if(q>=55296){p=q&64512
if(p===55296){o=r+1
o=!(o<m&&(a.charCodeAt(o)&64512)===56320)}else o=!1
if(!o)if(p===56320){p=r-1
p=!(p>=0&&(a.charCodeAt(p)&64512)===55296)}else p=!1
else p=!0
if(p){if(r>s)n.eC(a,s,r)
s=r+1
n.a5(92)
n.a5(117)
n.a5(100)
p=q>>>8&15
n.a5(p<10?48+p:87+p)
p=q>>>4&15
n.a5(p<10?48+p:87+p)
p=q&15
n.a5(p<10?48+p:87+p)}}continue}if(q<32){if(r>s)n.eC(a,s,r)
s=r+1
n.a5(92)
switch(q){case 8:n.a5(98)
break
case 9:n.a5(116)
break
case 10:n.a5(110)
break
case 12:n.a5(102)
break
case 13:n.a5(114)
break
default:n.a5(117)
n.a5(48)
n.a5(48)
p=q>>>4&15
n.a5(p<10?48+p:87+p)
p=q&15
n.a5(p<10?48+p:87+p)
break}}else if(q===34||q===92){if(r>s)n.eC(a,s,r)
s=r+1
n.a5(92)
n.a5(q)}}if(s===0)n.aB(a)
else if(s<m)n.eC(a,s,m)},
eU(a){var s,r,q,p
for(s=this.a,r=s.length,q=0;q<r;++q){p=s[q]
if(a==null?p==null:a===p)throw A.c(new A.iA(a,null))}s.push(a)},
eB(a){var s,r,q,p,o=this
if(o.jB(a))return
o.eU(a)
try{s=o.b.$1(a)
if(!o.jB(s)){q=A.wK(a,null,o.gi5())
throw A.c(q)}o.a.pop()}catch(p){r=A.E(p)
q=A.wK(a,r,o.gi5())
throw A.c(q)}},
jB(a){var s,r=this
if(typeof a=="number"){if(!isFinite(a))return!1
r.oV(a)
return!0}else if(a===!0){r.aB("true")
return!0}else if(a===!1){r.aB("false")
return!0}else if(a==null){r.aB("null")
return!0}else if(typeof a=="string"){r.aB('"')
r.jC(a)
r.aB('"')
return!0}else if(t.j.b(a)){r.eU(a)
r.oT(a)
r.a.pop()
return!0}else if(t.av.b(a)){r.eU(a)
s=r.oU(a)
r.a.pop()
return s}else return!1},
oT(a){var s,r,q=this
q.aB("[")
s=J.aa(a)
if(s.gaO(a)){q.eB(s.i(a,0))
for(r=1;r<s.gk(a);++r){q.aB(",")
q.eB(s.i(a,r))}}q.aB("]")},
oU(a){var s,r,q,p,o=this,n={}
if(a.gE(a)){o.aB("{}")
return!0}s=a.gk(a)*2
r=A.b4(s,null,!1,t.X)
q=n.a=0
n.b=!0
a.ad(0,new A.t4(n,r))
if(!n.b)return!1
o.aB("{")
for(p='"';q<s;q+=2,p=',"'){o.aB(p)
o.jC(A.ak(r[q]))
o.aB('":')
o.eB(r[q+1])}o.aB("}")
return!0}}
A.t4.prototype={
$2(a,b){var s,r,q,p
if(typeof a!="string")this.a.b=!1
s=this.b
r=this.a
q=r.a
p=r.a=q+1
s[q]=a
r.a=p+1
s[p]=b},
$S:42}
A.t2.prototype={
gi5(){var s=this.c
return s instanceof A.Z?s.j(0):null},
oV(a){this.c.eA(B.ab.j(a))},
aB(a){this.c.eA(a)},
eC(a,b,c){this.c.eA(B.a.t(a,b,c))},
a5(a){this.c.a5(a)}}
A.iD.prototype={
gbK(){return"iso-8859-1"},
b9(a){return B.bn.av(a)},
aI(a){var s=B.ac.av(a)
return s},
gd6(){return B.ac}}
A.iF.prototype={}
A.iE.prototype={
bd(a){var s=new A.dv(a)
if(!this.a)return new A.k5(s)
return new A.t5(s)}}
A.k5.prototype={
n(){this.a.a.a.a_()
this.a=null},
q(a,b){this.ae(b,0,J.aM(b),!1)},
ht(a,b,c,d){var s=this.a
s.toString
s.a.a.N(A.bI(a,b,c))},
ae(a,b,c,d){A.aI(b,c,J.aM(a))
if(b===c)return
if(!t.p.b(a))A.BT(a,b,c)
this.ht(a,b,c,!1)}}
A.t5.prototype={
ae(a,b,c,d){var s,r,q,p,o="Stream is already closed",n=J.aa(a)
A.aI(b,c,n.gk(a))
for(s=b;s<c;++s){r=n.i(a,s)
if(r>255||r<0){if(s>b){q=this.a
q.toString
p=A.bI(a,b,s)
q=q.a.a
if((q.e&2)!==0)A.r(A.z(o))
q.bR(p)}q=this.a
q.toString
p=A.bI(B.bq,0,1)
q=q.a.a
if((q.e&2)!==0)A.r(A.z(o))
q.bR(p)
b=s+1}}if(b<c)this.ht(a,b,c,!1)}}
A.nI.prototype={
bk(a){return new A.c9(A.DK(),a,t.it)}}
A.t6.prototype={
ae(a,b,c,d){var s=this
c=A.aI(b,c,a.length)
if(b<c){if(s.d){if(a.charCodeAt(b)===10)++b
s.d=!1}s.kX(a,b,c,d)}if(d)s.n()},
n(){var s=this,r=s.b
if(r!=null)s.a.a.a.N(s.fv(r,""))
s.a.a.a.a_()},
kX(a,b,c,d){var s,r,q,p,o,n,m,l,k=this,j=k.b
for(s=k.a.a.a,r=b,q=r,p=0;r<c;++r,p=o){o=a.charCodeAt(r)
if(o!==13){if(o!==10)continue
if(p===13){q=r+1
continue}}n=B.a.t(a,q,r)
if(j!=null){n=k.fv(j,n)
j=null}if((s.e&2)!==0)A.r(A.z("Stream is already closed"))
s.bR(n)
q=r+1}if(q<c){m=B.a.t(a,q,c)
if(d){s.N(j!=null?k.fv(j,m):m)
return}if(j==null)k.b=m
else{l=k.c
if(l==null)l=k.c=new A.Z("")
if(j.length!==0){l.a+=j
k.b=""}l.a+=m}}else k.d=p===13},
fv(a,b){var s,r
this.b=null
if(a.length!==0)return a+b
s=this.c
r=s.a+=b
s.a=""
return r.charCodeAt(0)==0?r:r}}
A.ez.prototype={
ag(a,b){this.e.ag(a,b)},
$iah:1}
A.jm.prototype={
q(a,b){this.ae(b,0,b.length,!1)}}
A.ts.prototype={
a5(a){var s=this.a,r=A.aQ(a)
if((s.a+=r).length>16)this.f6()},
eA(a){if(this.a.a.length!==0)this.f6()
this.b.q(0,a)},
f6(){var s=this.a,r=s.a
s.a=""
this.b.q(0,r.charCodeAt(0)==0?r:r)}}
A.hv.prototype={
n(){},
ae(a,b,c,d){var s,r,q
if(b!==0||c!==a.length)for(s=this.a,r=b;r<c;++r){q=A.aQ(a.charCodeAt(r))
s.a+=q}else this.a.a+=a
if(d)this.n()},
q(a,b){this.a.a+=b}}
A.dv.prototype={
q(a,b){this.a.a.N(b)},
ae(a,b,c,d){var s=b===0&&c===a.length,r=this.a.a
if(s)r.N(a)
else r.N(B.a.t(a,b,c))
if(d)r.a_()},
n(){this.a.a.a_()}}
A.kB.prototype={
n(){var s,r,q,p=this.c
this.a.nD(p)
s=p.a
r=this.b
if(s.length!==0){q=s.charCodeAt(0)==0?s:s
p.a=""
r.ae(q,0,q.length,!0)}else r.n()},
q(a,b){this.ae(b,0,J.aM(b),!1)},
ae(a,b,c,d){var s,r=this,q=r.c,p=r.a.cQ(a,b,c,!1)
p=q.a+=p
if(p.length!==0){s=p.charCodeAt(0)==0?p:p
r.b.ae(s,0,s.length,d)
q.a=""
return}if(d)r.n()}}
A.jz.prototype={
gbK(){return"utf-8"},
aI(a){return new A.cI(!1).cQ(a,0,null,!0)},
b9(a){return B.o.av(a)},
gd6(){return B.aE}}
A.jB.prototype={
av(a){var s,r,q=A.aI(0,null,a.length)
if(q===0)return new Uint8Array(0)
s=new Uint8Array(q*3)
r=new A.kC(s)
if(r.hO(a,0,q)!==q)r.dX()
return B.e.bQ(s,0,r.b)},
bd(a){return new A.tI(new A.jP(a),new Uint8Array(1024))}}
A.kC.prototype={
dX(){var s=this,r=s.c,q=s.b,p=s.b=q+1
r.$flags&2&&A.B(r)
r[q]=239
q=s.b=p+1
r[p]=191
s.b=q+1
r[q]=189},
iB(a,b){var s,r,q,p,o=this
if((b&64512)===56320){s=65536+((a&1023)<<10)|b&1023
r=o.c
q=o.b
p=o.b=q+1
r.$flags&2&&A.B(r)
r[q]=s>>>18|240
q=o.b=p+1
r[p]=s>>>12&63|128
p=o.b=q+1
r[q]=s>>>6&63|128
o.b=p+1
r[p]=s&63|128
return!0}else{o.dX()
return!1}},
hO(a,b,c){var s,r,q,p,o,n,m,l,k=this
if(b!==c&&(a.charCodeAt(c-1)&64512)===55296)--c
for(s=k.c,r=s.$flags|0,q=s.length,p=b;p<c;++p){o=a.charCodeAt(p)
if(o<=127){n=k.b
if(n>=q)break
k.b=n+1
r&2&&A.B(s)
s[n]=o}else{n=o&64512
if(n===55296){if(k.b+4>q)break
m=p+1
if(k.iB(o,a.charCodeAt(m)))p=m}else if(n===56320){if(k.b+3>q)break
k.dX()}else if(o<=2047){n=k.b
l=n+1
if(l>=q)break
k.b=l
r&2&&A.B(s)
s[n]=o>>>6|192
k.b=l+1
s[l]=o&63|128}else{n=k.b
if(n+2>=q)break
l=k.b=n+1
r&2&&A.B(s)
s[n]=o>>>12|224
n=k.b=l+1
s[l]=o>>>6&63|128
k.b=n+1
s[n]=o&63|128}}}return p}}
A.tI.prototype={
n(){if(this.a!==0){this.ae("",0,0,!0)
return}this.d.a.a.a_()},
ae(a,b,c,d){var s,r,q,p,o,n=this
n.b=0
s=b===c
if(s&&!d)return
r=n.a
if(r!==0){if(n.iB(r,!s?a.charCodeAt(b):0))++b
n.a=0}s=n.d
r=n.c
q=c-1
p=r.length-3
do{b=n.hO(a,b,c)
o=d&&b===c
if(b===q&&(a.charCodeAt(b)&64512)===55296){if(d&&n.b<p)n.dX()
else n.a=a.charCodeAt(b);++b}s.q(0,B.e.bQ(r,0,n.b))
if(o)s.n()
n.b=0}while(b<c)
if(d)n.n()}}
A.jA.prototype={
bd(a){return new A.kB(new A.cI(this.a),new A.dv(a),new A.Z(""))},
bk(a){return this.hm(a)}}
A.cI.prototype={
cQ(a,b,c,d){var s,r,q,p,o,n,m=this,l=A.aI(b,c,J.aM(a))
if(b===l)return""
if(a instanceof Uint8Array){s=a
r=s
q=0}else{r=A.Cq(a,b,l)
l-=b
q=b
b=0}if(d&&l-b>=15){p=m.a
o=A.Cp(p,r,b,l)
if(o!=null){if(!p)return o
if(o.indexOf("\ufffd")<0)return o}}o=m.f3(r,b,l,d)
p=m.b
if((p&1)!==0){n=A.y3(p)
m.b=0
throw A.c(A.ai(n,a,q+m.c))}return o},
f3(a,b,c,d){var s,r,q=this
if(c-b>1000){s=B.b.R(b+c,2)
r=q.f3(a,b,s,!1)
if((q.b&1)!==0)return r
return r+q.f3(a,s,c,d)}return q.mV(a,b,c,d)},
nD(a){var s,r=this.b
this.b=0
if(r<=32)return
if(this.a){s=A.aQ(65533)
a.a+=s}else throw A.c(A.ai(A.y3(77),null,null))},
mV(a,b,c,d){var s,r,q,p,o,n,m,l=this,k=65533,j=l.b,i=l.c,h=new A.Z(""),g=b+1,f=a[b]
A:for(s=l.a;;){for(;;g=p){r="AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAFFFFFFFFFFFFFFFFGGGGGGGGGGGGGGGGHHHHHHHHHHHHHHHHHHHHHHHHHHHIHHHJEEBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBKCCCCCCCCCCCCDCLONNNMEEEEEEEEEEE".charCodeAt(f)&31
i=j<=32?f&61694>>>r:(f&63|i<<6)>>>0
j=" \x000:XECCCCCN:lDb \x000:XECCCCCNvlDb \x000:XECCCCCN:lDb AAAAA\x00\x00\x00\x00\x00AAAAA00000AAAAA:::::AAAAAGG000AAAAA00KKKAAAAAG::::AAAAA:IIIIAAAAA000\x800AAAAA\x00\x00\x00\x00 AAAAA".charCodeAt(j+r)
if(j===0){q=A.aQ(i)
h.a+=q
if(g===c)break A
break}else if((j&1)!==0){if(s)switch(j){case 69:case 67:q=A.aQ(k)
h.a+=q
break
case 65:q=A.aQ(k)
h.a+=q;--g
break
default:q=A.aQ(k)
h.a=(h.a+=q)+q
break}else{l.b=j
l.c=g-1
return""}j=0}if(g===c)break A
p=g+1
f=a[g]}p=g+1
f=a[g]
if(f<128){for(;;){if(!(p<c)){o=c
break}n=p+1
f=a[p]
if(f>=128){o=n-1
p=n
break}p=n}if(o-g<20)for(m=g;m<o;++m){q=A.aQ(a[m])
h.a+=q}else{q=A.bI(a,g,o)
h.a+=q}if(o===c)break A
g=p}else g=p}if(d&&j>32)if(s){s=A.aQ(k)
h.a+=s}else{l.b=77
l.c=c
return""}l.b=j
l.c=i
s=h.a
return s.charCodeAt(0)==0?s:s}}
A.kD.prototype={}
A.az.prototype={
by(a){var s,r,q=this,p=q.c
if(p===0)return q
s=!q.a
r=q.b
p=A.bf(p,r)
return new A.az(p===0?!1:s,r,p)},
le(a){var s,r,q,p,o,n,m,l=this,k=l.c
if(k===0)return $.ci()
s=k-a
if(s<=0)return l.a?$.wd():$.ci()
r=l.b
q=new Uint16Array(s)
for(p=a;p<k;++p)q[p-a]=r[p]
o=l.a
n=A.bf(s,q)
m=new A.az(n===0?!1:o,q,n)
if(o)for(p=0;p<a;++p)if(r[p]!==0)return m.eM(0,$.kU())
return m},
cL(a,b){var s,r,q,p,o,n,m,l,k,j=this
if(b<0)throw A.c(A.H("shift-amount must be posititve "+b,null))
s=j.c
if(s===0)return j
r=B.b.R(b,16)
q=B.b.aS(b,16)
if(q===0)return j.le(r)
p=s-r
if(p<=0)return j.a?$.wd():$.ci()
o=j.b
n=new Uint16Array(p)
A.BC(o,s,b,n)
s=j.a
m=A.bf(p,n)
l=new A.az(m===0?!1:s,n,m)
if(s){if((o[r]&B.b.cK(1,q)-1)>>>0!==0)return l.eM(0,$.kU())
for(k=0;k<r;++k)if(o[k]!==0)return l.eM(0,$.kU())}return l},
a0(a,b){var s,r=this.a
if(r===b.a){s=A.qS(this.b,this.c,b.b,b.c)
return r?0-s:s}return r?-1:1},
eP(a,b){var s,r,q,p=this,o=p.c,n=a.c
if(o<n)return a.eP(p,b)
if(o===0)return $.ci()
if(n===0)return p.a===b?p:p.by(0)
s=o+1
r=new Uint16Array(s)
A.Bx(p.b,o,a.b,n,r)
q=A.bf(s,r)
return new A.az(q===0?!1:b,r,q)},
dF(a,b){var s,r,q,p=this,o=p.c
if(o===0)return $.ci()
s=a.c
if(s===0)return p.a===b?p:p.by(0)
r=new Uint16Array(o)
A.jM(p.b,o,a.b,s,r)
q=A.bf(o,r)
return new A.az(q===0?!1:b,r,q)},
dw(a,b){var s,r,q=this,p=q.c
if(p===0)return b
s=b.c
if(s===0)return q
r=q.a
if(r===b.a)return q.eP(b,r)
if(A.qS(q.b,p,b.b,s)>=0)return q.dF(b,r)
return b.dF(q,!r)},
eM(a,b){var s,r,q=this,p=q.c
if(p===0)return b.by(0)
s=b.c
if(s===0)return q
r=q.a
if(r!==b.a)return q.eP(b,r)
if(A.qS(q.b,p,b.b,s)>=0)return q.dF(b,r)
return b.dF(q,!r)},
aL(a,b){var s,r,q,p,o,n,m,l=this.c,k=b.c
if(l===0||k===0)return $.ci()
s=l+k
r=this.b
q=b.b
p=new Uint16Array(s)
for(o=0;o<k;){A.xx(q[o],r,0,p,o,l);++o}n=this.a!==b.a
m=A.bf(s,p)
return new A.az(m===0?!1:n,p,m)},
lc(a){var s,r,q,p
if(this.c<a.c)return $.ci()
this.hK(a)
s=$.vy.aV()-$.h1.aV()
r=A.vA($.vx.aV(),$.h1.aV(),$.vy.aV(),s)
q=A.bf(s,r)
p=new A.az(!1,r,q)
return this.a!==a.a&&q>0?p.by(0):p},
m1(a){var s,r,q,p=this
if(p.c<a.c)return p
p.hK(a)
s=A.vA($.vx.aV(),0,$.h1.aV(),$.h1.aV())
r=A.bf($.h1.aV(),s)
q=new A.az(!1,s,r)
if($.vz.aV()>0)q=q.cL(0,$.vz.aV())
return p.a&&q.c>0?q.by(0):q},
hK(a){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c=this,b=c.c
if(b===$.xu&&a.c===$.xw&&c.b===$.xt&&a.b===$.xv)return
s=a.b
r=a.c
q=16-B.b.giL(s[r-1])
if(q>0){p=new Uint16Array(r+5)
o=A.xs(s,r,q,p)
n=new Uint16Array(b+5)
m=A.xs(c.b,b,q,n)}else{n=A.vA(c.b,0,b,b+2)
o=r
p=s
m=b}l=p[o-1]
k=m-o
j=new Uint16Array(m)
i=A.vB(p,o,k,j)
h=m+1
g=n.$flags|0
if(A.qS(n,m,j,i)>=0){g&2&&A.B(n)
n[m]=1
A.jM(n,h,j,i,n)}else{g&2&&A.B(n)
n[m]=0}f=new Uint16Array(o+2)
f[o]=1
A.jM(f,o+1,p,o,f)
e=m-1
while(k>0){d=A.By(l,n,e);--k
A.xx(d,f,0,n,k,o)
if(n[e]<d){i=A.vB(f,o,k,j)
A.jM(n,h,j,i,n)
while(--d,n[e]<d)A.jM(n,h,j,i,n)}--e}$.xt=c.b
$.xu=b
$.xv=s
$.xw=r
$.vx.b=n
$.vy.b=h
$.h1.b=o
$.vz.b=q},
gv(a){var s,r,q,p=new A.qT(),o=this.c
if(o===0)return 6707
s=this.a?83585:429689
for(r=this.b,q=0;q<o;++q)s=p.$2(s,r[q])
return new A.qU().$1(s)},
D(a,b){if(b==null)return!1
return b instanceof A.az&&this.a0(0,b)===0},
j(a){var s,r,q,p,o,n=this,m=n.c
if(m===0)return"0"
if(m===1){if(n.a)return B.b.j(-n.b[0])
return B.b.j(n.b[0])}s=A.u([],t.s)
m=n.a
r=m?n.by(0):n
while(r.c>1){q=$.wc()
if(q.c===0)A.r(B.aQ)
p=r.m1(q).j(0)
s.push(p)
o=p.length
if(o===1)s.push("000")
if(o===2)s.push("00")
if(o===3)s.push("0")
r=r.lc(q)}s.push(B.b.j(r.b[0]))
if(m)s.push("-")
return new A.da(s,t.hF).o3(0)},
$ia7:1}
A.qT.prototype={
$2(a,b){a=a+b&536870911
a=a+((a&524287)<<10)&536870911
return a^a>>>6},
$S:173}
A.qU.prototype={
$1(a){a=a+((a&67108863)<<3)&536870911
a^=a>>>11
return a+((a&16383)<<15)&536870911},
$S:174}
A.jX.prototype={
iG(a,b,c){var s=this.a
if(s!=null)if(c!=null)s.register(a,b,c)
else s.register(a,b)},
iW(a){var s=this.a
if(s!=null)s.unregister(a)}}
A.bS.prototype={
D(a,b){var s
if(b==null)return!1
s=!1
if(b instanceof A.bS)if(this.a===b.a)s=this.b===b.b
return s},
gv(a){return A.c_(this.a,this.b,B.d,B.d,B.d,B.d)},
a0(a,b){var s=B.b.a0(this.a,b.a)
if(s!==0)return s
return B.b.a0(this.b,b.b)},
j(a){var s=this,r=A.A5(A.x2(s)),q=A.ie(A.x0(s)),p=A.ie(A.wY(s)),o=A.ie(A.wZ(s)),n=A.ie(A.x_(s)),m=A.ie(A.x1(s)),l=A.wx(A.AK(s)),k=s.b,j=k===0?"":A.wx(k)
return r+"-"+q+"-"+p+" "+o+":"+n+":"+m+"."+l+j},
$ia7:1}
A.bT.prototype={
D(a,b){if(b==null)return!1
return b instanceof A.bT&&this.a===b.a},
gv(a){return B.b.gv(this.a)},
a0(a,b){return B.b.a0(this.a,b.a)},
j(a){var s,r,q,p,o,n=this.a,m=B.b.R(n,36e8),l=n%36e8
if(n<0){m=0-m
n=0-l
s="-"}else{n=l
s=""}r=B.b.R(n,6e7)
n%=6e7
q=r<10?"0":""
p=B.b.R(n,1e6)
o=p<10?"0":""
return s+m+":"+q+r+":"+o+p+"."+B.a.oq(B.b.j(n%1e6),6,"0")},
$ia7:1}
A.rp.prototype={
j(a){return this.aE()}}
A.V.prototype={
gbz(){return A.AJ(this)}}
A.hU.prototype={
j(a){var s=this.a
if(s!=null)return"Assertion failed: "+A.ij(s)
return"Assertion failed"}}
A.c3.prototype={}
A.a1.prototype={
gf5(){return"Invalid argument"+(!this.a?"(s)":"")},
gf4(){return""},
j(a){var s=this,r=s.c,q=r==null?"":" ("+r+")",p=s.d,o=p==null?"":": "+A.q(p),n=s.gf5()+q+o
if(!s.a)return n
return n+s.gf4()+": "+A.ij(s.gfT())},
gfT(){return this.b}}
A.e4.prototype={
gfT(){return this.b},
gf5(){return"RangeError"},
gf4(){var s,r=this.e,q=this.f
if(r==null)s=q!=null?": Not less than or equal to "+A.q(q):""
else if(q==null)s=": Not greater than or equal to "+A.q(r)
else if(q>r)s=": Not in inclusive range "+A.q(r)+".."+A.q(q)
else s=q<r?": Valid value range is empty":": Only valid value is "+A.q(r)
return s}}
A.fl.prototype={
gfT(){return this.b},
gf5(){return"RangeError"},
gf4(){if(this.b<0)return": index must not be negative"
var s=this.f
if(s===0)return": no indices are valid"
return": index should be less than "+s},
gk(a){return this.f}}
A.fR.prototype={
j(a){return"Unsupported operation: "+this.a}}
A.jr.prototype={
j(a){var s=this.a
return s!=null?"UnimplementedError: "+s:"UnimplementedError"}}
A.aW.prototype={
j(a){return"Bad state: "+this.a}}
A.i9.prototype={
j(a){var s=this.a
if(s==null)return"Concurrent modification during iteration."
return"Concurrent modification during iteration: "+A.ij(s)+"."}}
A.iT.prototype={
j(a){return"Out of Memory"},
gbz(){return null},
$iV:1}
A.fI.prototype={
j(a){return"Stack Overflow"},
gbz(){return null},
$iV:1}
A.jW.prototype={
j(a){return"Exception: "+this.a},
$iJ:1}
A.aT.prototype={
j(a){var s,r,q,p,o,n,m,l,k,j,i,h=this.a,g=""!==h?"FormatException: "+h:"FormatException",f=this.c,e=this.b
if(typeof e=="string"){if(f!=null)s=f<0||f>e.length
else s=!1
if(s)f=null
if(f==null){if(e.length>78)e=B.a.t(e,0,75)+"..."
return g+"\n"+e}for(r=1,q=0,p=!1,o=0;o<f;++o){n=e.charCodeAt(o)
if(n===10){if(q!==o||!p)++r
q=o+1
p=!1}else if(n===13){++r
q=o+1
p=!0}}g=r>1?g+(" (at line "+r+", character "+(f-q+1)+")\n"):g+(" (at character "+(f+1)+")\n")
m=e.length
for(o=f;o<m;++o){n=e.charCodeAt(o)
if(n===10||n===13){m=o
break}}l=""
if(m-q>78){k="..."
if(f-q<75){j=q+75
i=q}else{if(m-f<75){i=m-75
j=m
k=""}else{i=f-36
j=f+36}l="..."}}else{j=m
i=q
k=""}return g+l+B.a.t(e,i,j)+k+"\n"+B.a.aL(" ",f-i+l.length)+"^\n"}else return f!=null?g+(" (at offset "+A.q(f)+")"):g},
$iJ:1,
gjh(){return this.a},
gdD(){return this.b},
gaa(){return this.c}}
A.iv.prototype={
gbz(){return null},
j(a){return"IntegerDivisionByZeroException"},
$iV:1,
$iJ:1}
A.m.prototype={
e6(a,b){return A.i4(this,A.p(this).h("m.E"),b)},
ba(a,b,c){return A.nR(this,b,A.p(this).h("m.E"),c)},
V(a,b){var s
for(s=this.gA(this);s.l();)if(J.A(s.gp(),b))return!0
return!1},
ca(a,b){var s=A.p(this).h("m.E")
if(b)s=A.an(this,s)
else{s=A.an(this,s)
s.$flags=1
s=s}return s},
jy(a){return this.ca(0,!0)},
gk(a){var s,r=this.gA(this)
for(s=0;r.l();)++s
return s},
gE(a){return!this.gA(this).l()},
gaO(a){return!this.gE(this)},
bN(a,b){return A.xh(this,b,A.p(this).h("m.E"))},
aT(a,b){return A.xa(this,b,A.p(this).h("m.E"))},
gai(a){var s=this.gA(this)
if(!s.l())throw A.c(A.bW())
return s.gp()},
W(a,b){var s,r
A.aH(b,"index")
s=this.gA(this)
for(r=b;s.l();){if(r===0)return s.gp();--r}throw A.c(A.it(b,b-r,this,null,"index"))},
j(a){return A.Ao(this,"(",")")}}
A.K.prototype={
j(a){return"MapEntry("+A.q(this.a)+": "+A.q(this.b)+")"}}
A.D.prototype={
gv(a){return A.k.prototype.gv.call(this,0)},
j(a){return"null"}}
A.k.prototype={$ik:1,
D(a,b){return this===b},
gv(a){return A.e3(this)},
j(a){return"Instance of '"+A.iY(this)+"'"},
ga4(a){return A.uv(this)},
toString(){return this.j(this)}}
A.ku.prototype={
j(a){return""},
$iaj:1}
A.Z.prototype={
gk(a){return this.a.length},
eA(a){var s=A.q(a)
this.a+=s},
a5(a){var s=A.aQ(a)
this.a+=s},
j(a){var s=this.a
return s.charCodeAt(0)==0?s:s}}
A.pK.prototype={
$2(a,b){throw A.c(A.ai("Illegal IPv6 address, "+a,this.a,b))},
$S:146}
A.hC.prototype={
giq(){var s,r,q,p,o=this,n=o.w
if(n===$){s=o.a
r=s.length!==0?s+":":""
q=o.c
p=q==null
if(!p||s==="file"){s=r+"//"
r=o.b
if(r.length!==0)s=s+r+"@"
if(!p)s+=q
r=o.d
if(r!=null)s=s+":"+A.q(r)}else s=r
s+=o.e
r=o.f
if(r!=null)s=s+"?"+r
r=o.r
if(r!=null)s=s+"#"+r
n=o.w=s.charCodeAt(0)==0?s:s}return n},
gos(){var s,r,q=this,p=q.x
if(p===$){s=q.e
if(s.length!==0&&s.charCodeAt(0)===47)s=B.a.a1(s,1)
r=s.length===0?B.J:A.nM(new A.a8(A.u(s.split("/"),t.s),A.DM(),t.iZ),t.N)
q.x!==$&&A.w9()
p=q.x=r}return p},
gv(a){var s,r=this,q=r.y
if(q===$){s=B.a.gv(r.giq())
r.y!==$&&A.w9()
r.y=s
q=s}return q},
gh8(){return this.b},
gbH(){var s=this.c
if(s==null)return""
if(B.a.K(s,"[")&&!B.a.S(s,"v",1))return B.a.t(s,1,s.length-1)
return s},
gdl(){var s=this.d
return s==null?A.xS(this.a):s},
gdn(){var s=this.f
return s==null?"":s},
ged(){var s=this.r
return s==null?"":s},
eg(a){var s=this.a
if(a.length!==s.length)return!1
return A.y9(a,s,0)>=0},
jv(a){var s,r,q,p,o,n,m,l,k=this,j=k.a
if(a!=null){a=A.vJ(a,0,a.length)
s=a!==j}else{a=j
s=!1}r=a==="file"
q=k.b
p=k.d
if(s)p=A.tF(p,a)
o=k.c
if(!(o!=null))o=q.length!==0||p!=null||r?"":null
n=k.e
if(!r)m=o!=null&&n.length!==0
else m=!0
if(m&&!B.a.K(n,"/"))n="/"+n
l=n
return A.hD(a,q,o,p,l,k.f,k.r)},
i2(a,b){var s,r,q,p,o,n,m
for(s=0,r=0;B.a.S(b,"../",r);){r+=3;++s}q=B.a.cw(a,"/")
for(;;){if(!(q>0&&s>0))break
p=B.a.eh(a,"/",q-1)
if(p<0)break
o=q-p
n=o!==2
m=!1
if(!n||o===3)if(a.charCodeAt(p+1)===46)n=!n||a.charCodeAt(p+2)===46
else n=m
else n=m
if(n)break;--s
q=p}return B.a.c9(a,q+1,null,B.a.a1(b,r-3*s))},
dr(a){return this.ds(A.di(a))},
ds(a){var s,r,q,p,o,n,m,l,k,j,i,h=this
if(a.gao().length!==0)return a
else{s=h.a
if(a.gfN()){r=a.jv(s)
return r}else{q=h.b
p=h.c
o=h.d
n=h.e
if(a.gj9())m=a.gef()?a.gdn():h.f
else{l=A.Co(h,n)
if(l>0){k=B.a.t(n,0,l)
n=a.gfM()?k+A.dy(a.gaQ()):k+A.dy(h.i2(B.a.a1(n,k.length),a.gaQ()))}else if(a.gfM())n=A.dy(a.gaQ())
else if(n.length===0)if(p==null)n=s.length===0?a.gaQ():A.dy(a.gaQ())
else n=A.dy("/"+a.gaQ())
else{j=h.i2(n,a.gaQ())
r=s.length===0
if(!r||p!=null||B.a.K(n,"/"))n=A.dy(j)
else n=A.vL(j,!r||p!=null)}m=a.gef()?a.gdn():null}}}i=a.gfO()?a.ged():null
return A.hD(s,q,p,o,n,m,i)},
gfN(){return this.c!=null},
gef(){return this.f!=null},
gfO(){return this.r!=null},
gj9(){return this.e.length===0},
gfM(){return B.a.K(this.e,"/")},
h6(){var s,r=this,q=r.a
if(q!==""&&q!=="file")throw A.c(A.R("Cannot extract a file path from a "+q+" URI"))
q=r.f
if((q==null?"":q)!=="")throw A.c(A.R(u.z))
q=r.r
if((q==null?"":q)!=="")throw A.c(A.R(u.A))
if(r.c!=null&&r.gbH()!=="")A.r(A.R(u.Q))
s=r.gos()
A.Cj(s,!1)
q=A.vp(B.a.K(r.e,"/")?"/":"",s,"/")
q=q.charCodeAt(0)==0?q:q
return q},
j(a){return this.giq()},
D(a,b){var s,r,q,p=this
if(b==null)return!1
if(p===b)return!0
s=!1
if(t.R.b(b))if(p.a===b.gao())if(p.c!=null===b.gfN())if(p.b===b.gh8())if(p.gbH()===b.gbH())if(p.gdl()===b.gdl())if(p.e===b.gaQ()){r=p.f
q=r==null
if(!q===b.gef()){if(q)r=""
if(r===b.gdn()){r=p.r
q=r==null
if(!q===b.gfO()){s=q?"":r
s=s===b.ged()}}}}return s},
$ijx:1,
gao(){return this.a},
gaQ(){return this.e}}
A.pJ.prototype={
gjz(){var s,r,q,p,o=this,n=null,m=o.c
if(m==null){m=o.a
s=o.b[0]+1
r=B.a.bn(m,"?",s)
q=m.length
if(r>=0){p=A.hE(m,r+1,q,256,!1,!1)
q=r}else p=n
m=o.c=new A.jT("data","",n,n,A.hE(m,s,q,128,!1,!1),p,n)}return m},
j(a){var s=this.a
return this.b[0]===-1?"data:"+s:s}}
A.bh.prototype={
gfN(){return this.c>0},
gfP(){return this.c>0&&this.d+1<this.e},
gef(){return this.f<this.r},
gfO(){return this.r<this.a.length},
gfM(){return B.a.S(this.a,"/",this.e)},
gj9(){return this.e===this.f},
eg(a){var s=a.length
if(s===0)return this.b<0
if(s!==this.b)return!1
return A.y9(a,this.a,0)>=0},
gao(){var s=this.w
return s==null?this.w=this.l7():s},
l7(){var s,r=this,q=r.b
if(q<=0)return""
s=q===4
if(s&&B.a.K(r.a,"http"))return"http"
if(q===5&&B.a.K(r.a,"https"))return"https"
if(s&&B.a.K(r.a,"file"))return"file"
if(q===7&&B.a.K(r.a,"package"))return"package"
return B.a.t(r.a,0,q)},
gh8(){var s=this.c,r=this.b+3
return s>r?B.a.t(this.a,r,s-1):""},
gbH(){var s=this.c
return s>0?B.a.t(this.a,s,this.d):""},
gdl(){var s,r=this
if(r.gfP())return A.yG(B.a.t(r.a,r.d+1,r.e))
s=r.b
if(s===4&&B.a.K(r.a,"http"))return 80
if(s===5&&B.a.K(r.a,"https"))return 443
return 0},
gaQ(){return B.a.t(this.a,this.e,this.f)},
gdn(){var s=this.f,r=this.r
return s<r?B.a.t(this.a,s+1,r):""},
ged(){var s=this.r,r=this.a
return s<r.length?B.a.a1(r,s+1):""},
hZ(a){var s=this.d+1
return s+a.length===this.e&&B.a.S(this.a,a,s)},
oA(){var s=this,r=s.r,q=s.a
if(r>=q.length)return s
return new A.bh(B.a.t(q,0,r),s.b,s.c,s.d,s.e,s.f,r,s.w)},
jv(a){var s,r,q,p,o,n,m,l,k,j,i,h=this,g=null
if(a!=null){a=A.vJ(a,0,a.length)
s=!(h.b===a.length&&B.a.K(h.a,a))}else{a=h.gao()
s=!1}r=a==="file"
q=h.c
p=q>0?B.a.t(h.a,h.b+3,q):""
o=h.gfP()?h.gdl():g
if(s)o=A.tF(o,a)
q=h.c
if(q>0)n=B.a.t(h.a,q,h.d)
else n=p.length!==0||o!=null||r?"":g
q=h.a
m=h.f
l=B.a.t(q,h.e,m)
if(!r)k=n!=null&&l.length!==0
else k=!0
if(k&&!B.a.K(l,"/"))l="/"+l
k=h.r
j=m<k?B.a.t(q,m+1,k):g
m=h.r
i=m<q.length?B.a.a1(q,m+1):g
return A.hD(a,p,n,o,l,j,i)},
dr(a){return this.ds(A.di(a))},
ds(a){if(a instanceof A.bh)return this.mi(this,a)
return this.is().ds(a)},
mi(a,b){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c=b.b
if(c>0)return b
s=b.c
if(s>0){r=a.b
if(r<=0)return b
q=r===4
if(q&&B.a.K(a.a,"file"))p=b.e!==b.f
else if(q&&B.a.K(a.a,"http"))p=!b.hZ("80")
else p=!(r===5&&B.a.K(a.a,"https"))||!b.hZ("443")
if(p){o=r+1
return new A.bh(B.a.t(a.a,0,o)+B.a.a1(b.a,c+1),r,s+o,b.d+o,b.e+o,b.f+o,b.r+o,a.w)}else return this.is().ds(b)}n=b.e
c=b.f
if(n===c){s=b.r
if(c<s){r=a.f
o=r-c
return new A.bh(B.a.t(a.a,0,r)+B.a.a1(b.a,c),a.b,a.c,a.d,a.e,c+o,s+o,a.w)}c=b.a
if(s<c.length){r=a.r
return new A.bh(B.a.t(a.a,0,r)+B.a.a1(c,s),a.b,a.c,a.d,a.e,a.f,s+(r-s),a.w)}return a.oA()}s=b.a
if(B.a.S(s,"/",n)){m=a.e
l=A.xK(this)
k=l>0?l:m
o=k-n
return new A.bh(B.a.t(a.a,0,k)+B.a.a1(s,n),a.b,a.c,a.d,m,c+o,b.r+o,a.w)}j=a.e
i=a.f
if(j===i&&a.c>0){while(B.a.S(s,"../",n))n+=3
o=j-n+1
return new A.bh(B.a.t(a.a,0,j)+"/"+B.a.a1(s,n),a.b,a.c,a.d,j,c+o,b.r+o,a.w)}h=a.a
l=A.xK(this)
if(l>=0)g=l
else for(g=j;B.a.S(h,"../",g);)g+=3
f=0
for(;;){e=n+3
if(!(e<=c&&B.a.S(s,"../",n)))break;++f
n=e}for(d="";i>g;){--i
if(h.charCodeAt(i)===47){if(f===0){d="/"
break}--f
d="/"}}if(i===g&&a.b<=0&&!B.a.S(h,"/",j)){n-=f*3
d=""}o=i-n+d.length
return new A.bh(B.a.t(h,0,i)+d+B.a.a1(s,n),a.b,a.c,a.d,j,c+o,b.r+o,a.w)},
h6(){var s,r=this,q=r.b
if(q>=0){s=!(q===4&&B.a.K(r.a,"file"))
q=s}else q=!1
if(q)throw A.c(A.R("Cannot extract a file path from a "+r.gao()+" URI"))
q=r.f
s=r.a
if(q<s.length){if(q<r.r)throw A.c(A.R(u.z))
throw A.c(A.R(u.A))}if(r.c<r.d)A.r(A.R(u.Q))
q=B.a.t(s,r.e,q)
return q},
gv(a){var s=this.x
return s==null?this.x=B.a.gv(this.a):s},
D(a,b){if(b==null)return!1
if(this===b)return!0
return t.R.b(b)&&this.a===b.j(0)},
is(){var s=this,r=null,q=s.gao(),p=s.gh8(),o=s.c>0?s.gbH():r,n=s.gfP()?s.gdl():r,m=s.a,l=s.f,k=B.a.t(m,s.e,l),j=s.r
l=l<j?s.gdn():r
return A.hD(q,p,o,n,k,l,j<m.length?s.ged():r)},
j(a){return this.a},
$ijx:1}
A.jT.prototype={}
A.im.prototype={
i(a,b){var s=!0
s=typeof b=="string"
if(s)A.wA(b)
return this.a.get(b)},
m(a,b,c){this.a.set(b,c)},
j(a){return"Expando:null"}}
A.u2.prototype={
$0(){var s=v.G.performance
if(t.m.b(s))if(s.measure!=null&&s.mark!=null&&s.clearMeasures!=null&&s.clearMarks!=null)return s
return null},
$S:161}
A.u0.prototype={
$0(){var s=v.G.JSON
if(t.m.b(s))return s
throw A.c(A.R("Missing JSON.parse() support"))},
$S:18}
A.vw.prototype={}
A.iR.prototype={
j(a){return"Promise was rejected with a value of `"+(this.a?"undefined":"null")+"`."},
$iJ:1}
A.n0.prototype={
$2(a,b){this.a.bc(new A.mZ(a),new A.n_(b),t.X)},
$S:167}
A.mZ.prototype={
$1(a){var s=this.a
return s.call(s)},
$S:107}
A.n_.prototype={
$2(a,b){var s=A.CF(a,b),r=this.a
r.call(r,s)
return s},
$S:135}
A.uB.prototype={
$1(a){var s,r,q,p
if(A.yj(a))return a
s=this.a
if(s.F(a))return s.i(0,a)
if(t.av.b(a)){r={}
s.m(0,a,r)
for(s=J.a0(a.ga3());s.l();){q=s.gp()
r[q]=this.$1(a.i(0,q))}return r}else if(t.e7.b(a)){p=[]
s.m(0,a,p)
B.c.a7(p,J.dI(a,this,t.z))
return p}else return a},
$S:151}
A.uS.prototype={
$1(a){return this.a.U(a)},
$S:12}
A.uT.prototype={
$1(a){if(a==null)return this.a.a9(new A.iR(a===undefined))
return this.a.a9(a)},
$S:12}
A.rY.prototype={
en(a){if(a<=0||a>4294967296)throw A.c(A.ay(u.E+a))
return Math.random()*a>>>0}}
A.rZ.prototype={
kQ(){var s=self.crypto
if(s!=null)if(s.getRandomValues!=null)return
throw A.c(A.R("No source of cryptographically secure random numbers available."))},
en(a){var s,r,q,p,o,n,m,l
if(a<=0||a>4294967296)throw A.c(A.ay(u.E+a))
if(a>255)if(a>65535)s=a>16777215?4:3
else s=2
else s=1
r=this.a
r.$flags&2&&A.B(r,11)
r.setUint32(0,0,!1)
q=4-s
p=A.O(Math.pow(256,s))
for(o=a-1,n=(a&o)===0;;){crypto.getRandomValues(J.cO(B.af.gau(r),q,s))
m=r.getUint32(0,!1)
if(n)return(m&o)>>>0
l=m%a
if(m-l+a<p)return l}}}
A.ii.prototype={
giE(){return this},
gv(a){return(J.U(this.a)^A.e3(this.b)^492929599)>>>0},
D(a,b){if(b==null)return!1
return b instanceof A.ii&&J.A(this.a,b.a)&&this.b===b.b}}
A.fV.prototype={
giE(){return null},
gv(a){return B.aa.gv(this.a)^842997089},
D(a,b){if(b==null)return!1
return b instanceof A.fV}}
A.fJ.prototype={
q(a,b){var s,r=this
if(r.b)throw A.c(A.z("Can't add a Stream to a closed StreamGroup."))
s=r.c
if(s===B.aG)r.e.cB(b,new A.oJ())
else if(s===B.aF)return b.O(null).u()
else r.e.cB(b,new A.oK(r,b))
return null},
lQ(){var s,r,q,p,o,n,m,l=this
l.c=B.aH
r=l.e
q=A.an(new A.aF(r,A.p(r).h("aF<1,2>")),l.$ti.h("K<C<1>,ac<1>?>"))
p=q.length
o=0
for(;o<q.length;q.length===p||(0,A.a6)(q),++o){n=q[o]
if(n.b!=null)continue
s=n.a
try{r.m(0,s,l.i0(s))}catch(m){r=l.io()
if(r!=null)r.iN(new A.oI())
throw m}}},
mn(){this.c=B.aI
for(var s=this.e,s=new A.b3(s,s.r,s.e);s.l();)s.d.aj()},
mp(){this.c=B.aH
for(var s=this.e,s=new A.b3(s,s.r,s.e);s.l();)s.d.am()},
io(){var s,r,q,p
this.c=B.aF
s=this.e
r=A.p(s).h("aF<1,2>")
q=t.bC
p=A.an(new A.fB(A.nR(new A.aF(s,r),new A.oH(this),r.h("m.E"),t.m2),q),q.h("m.E"))
s.aF(0)
return p.length===0?null:A.n4(p,t.H)},
i0(a){var s,r=this.a
r===$&&A.P()
s=a.az(r.gc4(r),new A.oG(this,a),r.gfz())
if(this.c===B.aI)s.aj()
return s}}
A.oJ.prototype={
$0(){return null},
$S:1}
A.oK.prototype={
$0(){return this.a.i0(this.b)},
$S(){return this.a.$ti.h("ac<1>()")}}
A.oI.prototype={
$1(a){},
$S:11}
A.oH.prototype={
$1(a){var s,r,q=a.b
try{if(q!=null){s=q.u()
return s}s=a.a.O(null).u()
return s}catch(r){return null}},
$S(){return this.a.$ti.h("n<~>?(K<C<1>,ac<1>?>)")}}
A.oG.prototype={
$0(){var s=this.a,r=s.e,q=r.H(0,this.b),p=q==null?null:q.u()
if(r.a===0)if(s.b){s=s.a
s===$&&A.P()
A.kQ(s.gaG())}return p},
$S:0}
A.eG.prototype={
j(a){return this.a}}
A.S.prototype={
i(a,b){var s,r=this
if(!r.fi(b))return null
s=r.c.i(0,r.a.$1(r.$ti.h("S.K").a(b)))
return s==null?null:s.b},
m(a,b,c){var s=this
if(!s.fi(b))return
s.c.m(0,s.a.$1(b),new A.K(b,c,s.$ti.h("K<S.K,S.V>")))},
a7(a,b){b.ad(0,new A.lw(this))},
bl(a,b,c){return this.c.bl(0,b,c)},
F(a){var s=this
if(!s.fi(a))return!1
return s.c.F(s.a.$1(s.$ti.h("S.K").a(a)))},
gbm(){var s=this.c,r=A.p(s).h("aF<1,2>")
return A.nR(new A.aF(s,r),new A.lx(this),r.h("m.E"),this.$ti.h("K<S.K,S.V>"))},
ad(a,b){this.c.ad(0,new A.ly(this,b))},
gE(a){return this.c.a===0},
ga3(){var s=this.c,r=A.p(s).h("bX<2>")
return A.nR(new A.bX(s,r),new A.lz(this),r.h("m.E"),this.$ti.h("S.K"))},
gk(a){return this.c.a},
cz(a,b,c,d){return this.c.cz(0,new A.lA(this,b,c,d),c,d)},
j(a){return A.nP(this)},
fi(a){return this.$ti.h("S.K").b(a)},
$ia3:1}
A.lw.prototype={
$2(a,b){this.a.m(0,a,b)
return b},
$S(){return this.a.$ti.h("~(S.K,S.V)")}}
A.lx.prototype={
$1(a){var s=a.b
return new A.K(s.a,s.b,this.a.$ti.h("K<S.K,S.V>"))},
$S(){return this.a.$ti.h("K<S.K,S.V>(K<S.C,K<S.K,S.V>>)")}}
A.ly.prototype={
$2(a,b){return this.b.$2(b.a,b.b)},
$S(){return this.a.$ti.h("~(S.C,K<S.K,S.V>)")}}
A.lz.prototype={
$1(a){return a.a},
$S(){return this.a.$ti.h("S.K(K<S.K,S.V>)")}}
A.lA.prototype={
$2(a,b){return this.b.$2(b.a,b.b)},
$S(){return this.a.$ti.I(this.c).I(this.d).h("K<1,2>(S.C,K<S.K,S.V>)")}}
A.fa.prototype={
bG(a,b){return J.A(a,b)},
fQ(a){return J.U(a)},
o2(a){return!0}}
A.eJ.prototype={
bG(a,b){var s,r,q,p,o
if(a===b)return!0
s=A.va(B.C.gns(),B.C.gnW(),B.C.go1(),this.$ti.h("eJ.E"),t.S)
for(r=a.gA(a),q=0;r.l();){p=r.gp()
o=s.i(0,p)
s.m(0,p,(o==null?0:o)+1);++q}for(r=b.gA(b);r.l();){p=r.gp()
o=s.i(0,p)
if(o==null||o===0)return!1
s.m(0,p,o-1);--q}return q===0}}
A.db.prototype={}
A.eB.prototype={
gv(a){return 3*J.U(this.b)+7*J.U(this.c)&2147483647},
D(a,b){if(b==null)return!1
return b instanceof A.eB&&J.A(this.b,b.b)&&J.A(this.c,b.c)}}
A.iI.prototype={
bG(a,b){var s,r,q,p,o
if(a==b)return!0
if(a==null||b==null)return!1
if(a.gk(a)!==b.gk(b))return!1
s=A.va(null,null,null,t.fA,t.S)
for(r=J.a0(a.ga3());r.l();){q=r.gp()
p=new A.eB(this,q,a.i(0,q))
o=s.i(0,p)
s.m(0,p,(o==null?0:o)+1)}for(r=J.a0(b.ga3());r.l();){q=r.gp()
p=new A.eB(this,q,b.i(0,q))
o=s.i(0,p)
if(o==null||o===0)return!1
s.m(0,p,o-1)}return!0},
fQ(a){var s,r,q,p,o,n
if(a==null)return B.aa.gv(null)
for(s=J.a0(a.ga3()),r=this.$ti.y[1],q=0;s.l();){p=s.gp()
o=J.U(p)
n=a.i(0,p)
q=q+3*o+7*J.U(n==null?r.a(n):n)&2147483647}q=q+(q<<3>>>0)&2147483647
q^=q>>>11
return q+(q<<15>>>0)&2147483647}}
A.iP.prototype={
sk(a,b){A.wU()},
q(a,b){return A.wU()}}
A.ju.prototype={}
A.l1.prototype={}
A.cv.prototype={}
A.hY.prototype={
n(){},
$ilH:1}
A.hZ.prototype={
nA(){if(this.w)throw A.c(A.z("Can't finalize a finalized Request."))
this.w=!0
return B.aK},
j(a){return this.a+" "+this.b.j(0)}}
A.le.prototype={
$2(a,b){return a.toLowerCase()===b.toLowerCase()},
$S:78}
A.lf.prototype={
$1(a){return B.a.gv(a.toLowerCase())},
$S:88}
A.lg.prototype={
eO(a,b,c,d,e,f,g){var s=this.b
if(s<100)throw A.c(A.H("Invalid status code "+s+".",null))
else{s=this.d
if(s!=null&&s<0)throw A.c(A.H("Invalid content length "+A.q(s)+".",null))}}}
A.i2.prototype={
ap(a){return this.kh(a)},
kh(b6){var s=0,r=A.i(t.n),q,p=2,o=[],n=[],m=this,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,b0,b1,b2,b3,b4,b5
var $async$ap=A.d(function(b7,b8){if(b7===1){o.push(b8)
s=p}for(;;)switch(s){case 0:if(m.b)throw A.c(A.wu("HTTP request failed. Client is already closed.",b6.b))
a4=v.G
l=new a4.AbortController()
a5=m.c
a5.push(l)
b6.hl()
s=3
return A.b(new A.cQ(A.xb(b6.y,t.f4)).h5(),$async$ap)
case 3:k=b8
p=5
j=b6
i=null
h=!1
g=null
if(j instanceof A.hP){if(h)a6=i
else{h=!0
a7=j.cx
i=a7
a6=a7}a6=a6!=null}else a6=!1
if(a6){if(h){a6=i
a8=a6}else{h=!0
a7=j.cx
i=a7
a8=a7}g=a8==null?t.p8.a(a8):a8
g.J(new A.lk(l))}a6=b6.b
a9=a6.j(0)
b0=!J.kY(k)?k:null
b1=t.N
f=A.T(b1,t.K)
e=b6.y.length
d=null
if(e!=null){d=e
J.kW(f,"content-length",d)}for(b2=b6.r,b2=new A.aF(b2,A.p(b2).h("aF<1,2>")).gA(0);b2.l();){b3=b2.d
b3.toString
c=b3
J.kW(f,c.a,c.b)}f=A.Ea(f)
f.toString
A.Q(f)
b2=l.signal
s=8
return A.b(A.aq(a4.fetch(a9,{method:b6.a,headers:f,body:b0,credentials:"same-origin",redirect:"follow",signal:b2}),t.m),$async$ap)
case 8:b=b8
a=b.headers.get("content-length")
a0=a!=null?A.vl(a,null):null
if(a0==null&&a!=null){f=A.wu("Invalid content-length header ["+a+"].",a6)
throw A.c(f)}a1=A.T(b1,b1)
b.headers.forEach(A.kI(new A.ll(a1)))
f=A.Cv(b6,b)
a4=b.status
a6=a1
b0=a0
A.di(b.url)
b1=b.statusText
f=new A.jl(A.yU(f),b6,a4,b1,b0,a6,!1,!0)
f.eO(a4,b0,a6,!1,!0,b1,b6)
q=f
n=[1]
s=6
break
n.push(7)
s=6
break
case 5:p=4
b5=o.pop()
a2=A.E(b5)
a3=A.M(b5)
A.yo(a2,a3,b6)
n.push(7)
s=6
break
case 4:n=[2]
case 6:p=2
B.c.H(a5,l)
s=n.pop()
break
case 7:case 1:return A.f(q,r)
case 2:return A.e(o.at(-1),r)}})
return A.h($async$ap,r)},
n(){var s,r,q
for(s=this.c,r=s.length,q=0;q<s.length;s.length===r||(0,A.a6)(s),++q)s[q].abort()
this.b=!0}}
A.lk.prototype={
$0(){return this.a.abort()},
$S:0}
A.ll.prototype={
$3(a,b,c){this.a.m(0,b.toLowerCase(),a)},
$2(a,b){return this.$3(a,b,null)},
$S:96}
A.tS.prototype={
$1(a){return A.eQ(this.a,this.b,a)},
$S:98}
A.u3.prototype={
$0(){var s=this.a,r=s.a
if(r!=null){s.a=null
r.L()}},
$S:0}
A.u4.prototype={
$0(){var s=0,r=A.i(t.H),q=1,p=[],o=this,n,m,l,k
var $async$$0=A.d(function(a,b){if(a===1){p.push(b)
s=q}for(;;)switch(s){case 0:q=3
o.a.c=!0
s=6
return A.b(A.aq(o.b.cancel(),t.X),$async$$0)
case 6:q=1
s=5
break
case 3:q=2
k=p.pop()
n=A.E(k)
m=A.M(k)
if(!o.a.b)A.yo(n,m,o.c)
s=5
break
case 2:s=1
break
case 5:return A.f(null,r)
case 1:return A.e(p.at(-1),r)}})
return A.h($async$$0,r)},
$S:3}
A.cQ.prototype={
h5(){var s=new A.l($.o,t.jz),r=new A.a9(s,t.iq),q=new A.jQ(new A.lv(r),new Uint8Array(1024))
this.B(q.gc4(q),!0,q.gaG(),r.gmP())
return s}}
A.lv.prototype={
$1(a){return this.a.U(new Uint8Array(A.vS(a)))},
$S:100}
A.bQ.prototype={
j(a){var s=this.b,r="ClientException: "+this.a
if(s!=null)return r+", uri="+s.j(0)
else return r},
$iJ:1}
A.op.prototype={
gfI(){var s,r
if(this.gbC()==null||!this.gbC().c.a.F("charset"))return B.l
s=this.gbC().c.a.i(0,"charset")
s.toString
r=A.wy(s)
return r==null?A.r(A.ai('Unsupported encoding "'+s+'".',null,null)):r},
siM(a){var s,r,q,p,o,n,m=this,l=m.gfI().b9(a)
m.l0()
m.y=A.yV(l)
s=m.gbC()
if(s==null){l=t.N
m.sbC(A.nS("text","plain",A.bD(["charset",m.gfI().gbK()],l,l)))}else{l=m.gbC()
if(l!=null){r=l.a
if(r!=="text"){l=r+"/"+l.b
l=l==="application/xml"||l==="application/xml-external-parsed-entity"||l==="application/xml-dtd"||B.a.bF(l,"+xml")}else l=!0}else l=!1
if(l&&!s.c.a.F("charset")){l=t.N
q=A.bD(["charset",m.gfI().gbK()],l,l)
p=s.a
o=s.b
n=A.wN(s.c,l,l)
n.a7(0,q)
m.sbC(A.nS(p,o,n))}}},
gbC(){var s=this.r.i(0,"content-type")
if(s==null)return null
return A.wR(s)},
sbC(a){this.r.m(0,"content-type",a.j(0))},
l0(){if(!this.w)return
throw A.c(A.z("Can't modify a finalized Request."))}}
A.hP.prototype={}
A.jG.prototype={}
A.e6.prototype={}
A.cz.prototype={}
A.jl.prototype={}
A.f0.prototype={}
A.fv.prototype={
j(a){var s=new A.Z(""),r=this.a
s.a=r
r+="/"
s.a=r
s.a=r+this.b
this.c.a.ad(0,new A.nV(s))
r=s.a
return r.charCodeAt(0)==0?r:r}}
A.nT.prototype={
$0(){var s,r,q,p,o,n,m,l,k,j=this.a,i=new A.p9(null,j),h=$.zy()
i.eK(h)
s=$.zx()
i.d8(s)
r=i.gfV().i(0,0)
r.toString
i.d8("/")
i.d8(s)
q=i.gfV().i(0,0)
q.toString
i.eK(h)
p=t.N
o=A.T(p,p)
for(;;){p=i.d=B.a.cA(";",j,i.c)
n=i.e=i.c
m=p!=null
p=m?i.e=i.c=p.gC():n
if(!m)break
p=i.d=h.cA(0,j,p)
i.e=i.c
if(p!=null)i.e=i.c=p.gC()
i.d8(s)
if(i.c!==i.e)i.d=null
p=i.d.i(0,0)
p.toString
i.d8("=")
n=i.d=s.cA(0,j,i.c)
l=i.e=i.c
m=n!=null
if(m){n=i.e=i.c=n.gC()
l=n}else n=l
if(m){if(n!==l)i.d=null
n=i.d.i(0,0)
n.toString
k=n}else k=A.DT(i)
n=i.d=h.cA(0,j,i.c)
i.e=i.c
if(n!=null)i.e=i.c=n.gC()
o.m(0,p,k)}i.nx()
return A.nS(r,q,o)},
$S:105}
A.nV.prototype={
$2(a,b){var s,r,q=this.a
q.a+="; "+a+"="
s=$.zv()
s=s.b.test(b)
r=q.a
if(s){q.a=r+'"'
s=A.yR(b,$.zj(),new A.nU(),null)
q.a=(q.a+=s)+'"'}else q.a=r+b},
$S:34}
A.nU.prototype={
$1(a){return"\\"+A.q(a.i(0,0))},
$S:26}
A.up.prototype={
$1(a){var s=a.i(0,1)
s.toString
return s},
$S:26}
A.cq.prototype={
D(a,b){if(b==null)return!1
return b instanceof A.cq&&this.b===b.b},
a0(a,b){return this.b-b.b},
gv(a){return this.b},
j(a){return this.a},
$ia7:1}
A.dX.prototype={
j(a){return"["+this.a.a+"] "+this.d+": "+this.b}}
A.dY.prototype={
gj3(){var s=this.b,r=s==null?null:s.a.length!==0,q=this.a
return r===!0?s.gj3()+"."+q:q},
go5(){var s,r
if(this.b==null){s=this.c
s.toString
r=s}else{s=$.v1().c
s.toString
r=s}return r},
P(a,b,c,d){var s,r,q=this,p=a.b
if(p>=q.go5().b){if((d==null||d===B.t)&&p>=2000){d=A.ec()
if(c==null)c="autogenerated stack trace for "+a.j(0)+" "+b}p=q.gj3()
s=Date.now()
$.wO=$.wO+1
r=new A.dX(a,b,p,new A.bS(s,0,!1),c,d)
if(q.b==null)q.i8(r)
else $.v1().i8(r)}},
oe(a,b){return this.P(a,b,null,null)},
f8(){if(this.b==null){var s=this.f
if(s==null)s=this.f=A.c2(!0,t.ag)
return new A.ao(s,A.p(s).h("ao<1>"))}else return $.v1().f8()},
i8(a){var s=this.f
return s==null?null:s.q(0,a)}}
A.nN.prototype={
$0(){var s,r,q=this.a
if(B.a.K(q,"."))A.r(A.H("name shouldn't start with a '.'",null))
if(B.a.bF(q,"."))A.r(A.H("name shouldn't end with a '.'",null))
s=B.a.cw(q,".")
if(s===-1)r=q!==""?A.vk(""):null
else{r=A.vk(B.a.t(q,0,s))
q=B.a.a1(q,s+1)}return A.wP(q,r,A.T(t.N,t.W))},
$S:117}
A.lY.prototype={
mD(a){var s,r,q=t.mf
A.yv("absolute",A.u([a,null,null,null,null,null,null,null,null,null,null,null,null,null,null],q))
s=this.a
s=s.aA(a)>0&&!s.bI(a)
if(s)return a
s=A.yC()
r=A.u([s,a,null,null,null,null,null,null,null,null,null,null,null,null,null,null],q)
A.yv("join",r)
return this.o4(new A.fX(r,t.lS))},
o4(a){var s,r,q,p,o,n,m,l,k
for(s=a.gA(0),r=new A.ek(s,new A.lZ()),q=this.a,p=!1,o=!1,n="";r.l();){m=s.gp()
if(q.bI(m)&&o){l=A.iU(m,q)
k=n.charCodeAt(0)==0?n:n
n=B.a.t(k,0,q.cD(k,!0))
l.b=n
if(q.dj(n))l.e[0]=q.gcf()
n=l.j(0)}else if(q.aA(m)>0){o=!q.bI(m)
n=m}else{if(!(m.length!==0&&q.fE(m[0])))if(p)n+=q.gcf()
n+=m}p=q.dj(m)}return n.charCodeAt(0)==0?n:n},
dE(a,b){var s=A.iU(b,this.a),r=s.d,q=A.a5(r).h("c7<1>")
r=A.an(new A.c7(r,new A.m_(),q),q.h("m.E"))
s.d=r
q=s.b
if(q!=null)B.c.o0(r,0,q)
return s.d},
fZ(a){var s
if(!this.lH(a))return a
s=A.iU(a,this.a)
s.fY()
return s.j(0)},
lH(a){var s,r,q,p,o,n,m,l=this.a,k=l.aA(a)
if(k!==0){if(l===$.kT())for(s=0;s<k;++s)if(a.charCodeAt(s)===47)return!0
r=k
q=47}else{r=0
q=null}for(p=a.length,s=r,o=null;s<p;++s,o=q,q=n){n=a.charCodeAt(s)
if(l.bo(n)){if(l===$.kT()&&n===47)return!0
if(q!=null&&l.bo(q))return!0
if(q===46)m=o==null||o===46||l.bo(o)
else m=!1
if(m)return!0}}if(q==null)return!0
if(l.bo(q))return!0
if(q===46)l=o==null||l.bo(o)||o===46
else l=!1
if(l)return!0
return!1},
oz(a){var s,r,q,p,o=this,n='Unable to find a path to "',m=o.a,l=m.aA(a)
if(l<=0)return o.fZ(a)
s=A.yC()
if(m.aA(s)<=0&&m.aA(a)>0)return o.fZ(a)
if(m.aA(a)<=0||m.bI(a))a=o.mD(a)
if(m.aA(a)<=0&&m.aA(s)>0)throw A.c(A.wV(n+a+'" from "'+s+'".'))
r=A.iU(s,m)
r.fY()
q=A.iU(a,m)
q.fY()
l=r.d
if(l.length!==0&&l[0]===".")return q.j(0)
l=r.b
p=q.b
if(l!=p)l=l==null||p==null||!m.h1(l,p)
else l=!1
if(l)return q.j(0)
for(;;){l=r.d
if(l.length!==0){p=q.d
l=p.length!==0&&m.h1(l[0],p[0])}else l=!1
if(!l)break
B.c.es(r.d,0)
B.c.es(r.e,1)
B.c.es(q.d,0)
B.c.es(q.e,1)}l=r.d
p=l.length
if(p!==0&&l[0]==="..")throw A.c(A.wV(n+a+'" from "'+s+'".'))
l=t.N
B.c.fR(q.d,0,A.b4(p,"..",!1,l))
p=q.e
p[0]=""
B.c.fR(p,1,A.b4(r.d.length,m.gcf(),!1,l))
m=q.d
l=m.length
if(l===0)return"."
if(l>1&&B.c.gaP(m)==="."){B.c.jt(q.d)
m=q.e
m.pop()
m.pop()
m.push("")}q.b=""
q.ju()
return q.j(0)},
jn(a){var s,r,q=this,p=A.yl(a)
if(p.gao()==="file"&&q.a===$.hL())return p.j(0)
else if(p.gao()!=="file"&&p.gao()!==""&&q.a!==$.hL())return p.j(0)
s=q.fZ(q.a.h0(A.yl(p)))
r=q.oz(s)
return q.dE(0,r).length>q.dE(0,s).length?s:r}}
A.lZ.prototype={
$1(a){return a!==""},
$S:27}
A.m_.prototype={
$1(a){return a.length!==0},
$S:27}
A.uh.prototype={
$1(a){return a==null?"null":'"'+a+'"'},
$S:136}
A.nD.prototype={
kc(a){var s=this.aA(a)
if(s>0)return B.a.t(a,0,s)
return this.bI(a)?a[0]:null},
h1(a,b){return a===b}}
A.o_.prototype={
ju(){var s,r,q=this
for(;;){s=q.d
if(!(s.length!==0&&B.c.gaP(s)===""))break
B.c.jt(q.d)
q.e.pop()}s=q.e
r=s.length
if(r!==0)s[r-1]=""},
fY(){var s,r,q,p,o,n=this,m=A.u([],t.s)
for(s=n.d,r=s.length,q=0,p=0;p<s.length;s.length===r||(0,A.a6)(s),++p){o=s[p]
if(!(o==="."||o===""))if(o==="..")if(m.length!==0)m.pop()
else ++q
else m.push(o)}if(n.b==null)B.c.fR(m,0,A.b4(q,"..",!1,t.N))
if(m.length===0&&n.b==null)m.push(".")
n.d=m
s=n.a
n.e=A.b4(m.length+1,s.gcf(),!0,t.N)
r=n.b
if(r==null||m.length===0||!s.dj(r))n.e[0]=""
r=n.b
if(r!=null&&s===$.kT())n.b=A.hK(r,"/","\\")
n.ju()},
j(a){var s,r,q,p,o=this.b
o=o!=null?o:""
for(s=this.d,r=s.length,q=this.e,p=0;p<r;++p)o=o+q[p]+s[p]
o+=B.c.gaP(q)
return o.charCodeAt(0)==0?o:o}}
A.iV.prototype={
j(a){return"PathException: "+this.a},
$iJ:1}
A.pa.prototype={
j(a){return this.gbK()}}
A.o0.prototype={
fE(a){return B.a.V(a,"/")},
bo(a){return a===47},
dj(a){var s=a.length
return s!==0&&a.charCodeAt(s-1)!==47},
cD(a,b){if(a.length!==0&&a.charCodeAt(0)===47)return 1
return 0},
aA(a){return this.cD(a,!1)},
bI(a){return!1},
h0(a){var s
if(a.gao()===""||a.gao()==="file"){s=a.gaQ()
return A.vM(s,0,s.length,B.l,!1)}throw A.c(A.H("Uri "+a.j(0)+" must have scheme 'file:'.",null))},
gbK(){return"posix"},
gcf(){return"/"}}
A.pL.prototype={
fE(a){return B.a.V(a,"/")},
bo(a){return a===47},
dj(a){var s=a.length
if(s===0)return!1
if(a.charCodeAt(s-1)!==47)return!0
return B.a.bF(a,"://")&&this.aA(a)===s},
cD(a,b){var s,r,q,p=a.length
if(p===0)return 0
if(a.charCodeAt(0)===47)return 1
for(s=0;s<p;++s){r=a.charCodeAt(s)
if(r===47)return 0
if(r===58){if(s===0)return 0
q=B.a.bn(a,"/",B.a.S(a,"//",s+1)?s+3:s)
if(q<=0)return p
if(!b||p<q+3)return q
if(!B.a.K(a,"file://"))return q
p=A.yD(a,q+1)
return p==null?q:p}}return 0},
aA(a){return this.cD(a,!1)},
bI(a){return a.length!==0&&a.charCodeAt(0)===47},
h0(a){return a.j(0)},
gbK(){return"url"},
gcf(){return"/"}}
A.qe.prototype={
fE(a){return B.a.V(a,"/")},
bo(a){return a===47||a===92},
dj(a){var s=a.length
if(s===0)return!1
s=a.charCodeAt(s-1)
return!(s===47||s===92)},
cD(a,b){var s,r=a.length
if(r===0)return 0
if(a.charCodeAt(0)===47)return 1
if(a.charCodeAt(0)===92){if(r<2||a.charCodeAt(1)!==92)return 1
s=B.a.bn(a,"\\",2)
if(s>0){s=B.a.bn(a,"\\",s+1)
if(s>0)return s}return r}if(r<3)return 0
if(!A.yH(a.charCodeAt(0)))return 0
if(a.charCodeAt(1)!==58)return 0
r=a.charCodeAt(2)
if(!(r===47||r===92))return 0
return 3},
aA(a){return this.cD(a,!1)},
bI(a){return this.aA(a)===1},
h0(a){var s,r
if(a.gao()!==""&&a.gao()!=="file")throw A.c(A.H("Uri "+a.j(0)+" must have scheme 'file:'.",null))
s=a.gaQ()
if(a.gbH()===""){r=s.length
if(r>=3&&B.a.K(s,"/")&&A.yD(s,1)!=null){A.x5(0,0,r,"startIndex")
s=A.Eu(s,"/","",0)}}else s="\\\\"+a.gbH()+s
r=A.hK(s,"/","\\")
return A.vM(r,0,r.length,B.l,!1)},
mO(a,b){var s
if(a===b)return!0
if(a===47)return b===92
if(a===92)return b===47
if((a^b)!==32)return!1
s=a|32
return s>=97&&s<=122},
h1(a,b){var s,r
if(a===b)return!0
s=a.length
if(s!==b.length)return!1
for(r=0;r<s;++r)if(!this.mO(a.charCodeAt(r),b.charCodeAt(r)))return!1
return!0},
gbK(){return"windows"},
gcf(){return"\\"}}
A.hO.prototype={
ar(){var s=0,r=A.i(t.H),q=this,p,o,n,m
var $async$ar=A.d(function(a,b){if(a===1)return A.e(b,r)
for(;;)switch(s){case 0:if((q.a.a.a&30)===0){for(p=q.b,o=A.BX(p,p.r,A.p(p).c),n=o.$ti.c;o.l();){m=o.d;(m==null?n.a(m):m).L()}p.aF(0)}s=2
return A.b(q.c.a,$async$ar)
case 2:return A.f(null,r)}})
return A.h($async$ar,r)},
iQ(){var s=this.c
if((s.a.a&30)===0)s.L()},
b0(a,b){var s=new A.a9(new A.l($.o,t.D),t.h)
if((this.a.a.a&30)!==0)s.L()
else this.b.q(0,s)
return A.dT(new A.l_(a,s,b),b).J(new A.l0(this,s))}}
A.l_.prototype={
$0(){return this.a.$1(this.b.a)},
$S(){return this.c.h("n<0>()")}}
A.l0.prototype={
$0(){var s=this.b
this.a.b.H(0,s)
if((s.a.a&30)===0)s.L()},
$S:1}
A.ct.prototype={
j(a){return"PowerSyncCredentials<endpoint: "+this.a+" userId: "+A.q(this.c)+" expiresAt: "+A.q(this.d)+">"}}
A.f8.prototype={
ew(){var s=this
return A.bD(["op_id",s.a,"op",s.c.c,"type",s.d,"id",s.e,"tx_id",s.b,"data",s.r,"metadata",s.f,"old",s.w],t.N,t.z)},
j(a){var s=this
return"CrudEntry<"+s.b+"/"+s.a+" "+s.c.c+" "+s.d+"/"+s.e+" "+A.q(s.r)+">"},
D(a,b){var s=this
if(b==null)return!1
return b instanceof A.f8&&b.b===s.b&&b.a===s.a&&b.c===s.c&&b.d===s.d&&b.e===s.e&&B.x.bG(b.r,s.r)},
gv(a){var s=this
return A.c_(s.b,s.a,s.c.c,s.d,s.e,B.x.fQ(s.r))}}
A.fT.prototype={
aE(){return"UpdateType."+this.b},
ew(){return this.c}}
A.uQ.prototype={
$1(a){return new A.bc(A.vT(a.a))},
$S:148}
A.uP.prototype={
$1(a){var s=a.a
return s.gaO(s)},
$S:149}
A.f7.prototype={
j(a){return"CredentialsException: "+this.a},
$iJ:1}
A.e2.prototype={
j(a){return"SyncProtocolException: "+this.a},
$iJ:1}
A.de.prototype={
j(a){return"SyncResponseException: "+this.a+" "+this.b},
$iJ:1}
A.u1.prototype={
$1(a){var s
A.uR("["+a.d+"] "+a.a.a+": "+a.e.j(0)+": "+a.b)
s=a.r
if(s!=null)A.uR(s)
s=a.w
if(s!=null)A.uR(s)},
$S:36}
A.d0.prototype={
j(a){return v.G.String(this.a)},
gv(a){return A.O(v.G.Number(this.a))},
D(a,b){if(b==null)return!1
return b instanceof A.d0&&this.a===b.a},
$idU:1}
A.bc.prototype={
cE(a){var s=this.a
if(a instanceof A.bc)return new A.bc(s.cE(a.a))
else return new A.bc(s.cE(A.vT(a.a)))},
fD(a){return this.kw(A.vT(a))}}
A.lt.prototype={
$1(a){return a.b_(this.a,this.b)},
$S(){return this.b.h("n<0>(aJ)")}}
A.lr.prototype={
$1(a){return this.jH(a)},
jH(a){var s=0,r=A.i(t.I),q,p
var $async$$1=A.d(function(b,c){if(b===1)return A.e(c,r)
for(;;)switch(s){case 0:s=3
return A.b(A.d6(a,"target",null),$async$$1)
case 3:if(c!=="9223372036854775807"){q=null
s=1
break}s=4
return A.b(a.dA("SELECT 1 FROM ps_crud LIMIT 1"),$async$$1)
case 4:if(c!=null){q=null
s=1
break}s=5
return A.b(a.dA(u.B),$async$$1)
case 5:p=c
q=A.vO(p==null?null:p.i(0,"seq"))
s=1
break
case 1:return A.f(q,r)}})
return A.h($async$$1,r)},
$S:159}
A.ls.prototype={
$1(a){return this.jG(a)},
jG(a){var s=0,r=A.i(t.y),q,p=this,o,n
var $async$$1=A.d(function(b,c){if(b===1)return A.e(c,r)
for(;;)switch(s){case 0:s=3
return A.b(a.iX("SELECT 1 FROM ps_crud LIMIT 1"),$async$$1)
case 3:n=c
if(!n.gE(n)){q=!1
s=1
break}s=4
return A.b(a.iX(u.B),$async$$1)
case 4:o=c
if(A.O(o.gai(o).i(0,"seq"))!==p.a){q=!1
s=1
break}s=5
return A.b(A.d6(a,"target",p.b),$async$$1)
case 5:q=!0
s=1
break
case 1:return A.f(q,r)}})
return A.h($async$$1,r)},
$S:163}
A.ln.prototype={
$1(a){return this.jF(a)},
jF(a){var s=0,r=A.i(t.N),q,p=this,o
var $async$$1=A.d(function(b,c){if(b===1)return A.e(c,r)
for(;;)switch(s){case 0:s=3
return A.b(A.iX(a,p.a,p.b),$async$$1)
case 3:o=c
o.toString
q=o
s=1
break
case 1:return A.f(q,r)}})
return A.h($async$$1,r)},
$S:37}
A.dL.prototype={
j(a){return this.a},
$iJ:1}
A.lF.prototype={
h9(a,b){var s=this.b
return A.Bk(new A.ao(s,A.p(s).h("ao<1>")),a,this.a,"waitForCheckpointRequestsReady",new A.lG(this,b),t.hi)},
oQ(a){return this.h9(a,!0)}}
A.lG.prototype={
$1(a){var s,r,q
if(a instanceof A.h7)throw A.c(B.z)
s=a instanceof A.en
r=s?a.a:null
if(s){q=r.giE()
if(q!=null)A.ik(q.a,q.b)
return!0}if(a instanceof A.hl){if(this.b&&(this.a.c.a.a&30)===0)this.a.c.L()
return!1}},
$S:57}
A.cb.prototype={}
A.hl.prototype={}
A.en.prototype={}
A.h7.prototype={}
A.ft.prototype={$iar:1,$ib6:1}
A.dR.prototype={$iar:1}
A.lE.prototype={}
A.fS.prototype={$iar:1,$ib6:1}
A.m1.prototype={}
A.m2.prototype={
$1(a){return A.A1(t.f.a(a))},
$S:145}
A.mO.prototype={
ew(){var s,r,q,p,o=t.N,n=A.T(o,t.dV)
for(s=this.a,s=new A.aF(s,A.p(s).h("aF<1,2>")).gA(0),r=t.S;s.l();){q=s.d
p=q.a
q=q.b.a
n.m(0,p,A.bD(["priority",q[1],"at_last",q[0],"since_last",q[2],"target_count",q[3]],o,r))}return A.bD(["buckets",n],o,t.X)}}
A.mP.prototype={
$2(a,b){var s
t.f.a(b)
s=A.O(b.i(0,"priority"))
return new A.K(a,new A.kj([A.O(b.i(0,"at_last")),s,A.O(b.i(0,"since_last")),A.O(b.i(0,"target_count"))]),t.lx)},
$S:59}
A.ff.prototype={$iar:1,$ib6:1}
A.dM.prototype={$iar:1}
A.fb.prototype={$iar:1,$ib6:1}
A.f2.prototype={$iar:1,$ib6:1}
A.fj.prototype={$iar:1,$ib6:1}
A.fQ.prototype={$iar:1,$ib6:1}
A.nC.prototype={}
A.fN.prototype={}
A.lD.prototype={}
A.fr.prototype={
D(a,b){if(b==null)return!1
return b instanceof A.fr},
gv(a){return B.a.gv("legacy")}}
A.d9.prototype={
D(a,b){var s
if(b==null)return!1
if(b instanceof A.d9)s=b.a.a===this.a.a
else s=!1
return s},
gv(a){return B.b.gv(this.a.a)}}
A.pb.prototype={
aE(){return"SyncClientImplementation."+this.b}}
A.aK.prototype={
j(a){var s,r,q=this,p=A.u([],t.iE),o=q.a
if(o!=null)p.push(new A.N("core",o.a))
s=q.b
if(s!=null)p.push(new A.N("uploading",s))
r=q.c
if(r!=null)p.push(new A.N("downloadError",A.xf(null,r)))
r=q.d
if(r!=null)p.push(new A.N("uploadError",A.xf(null,r)))
return"SyncStatusUpdate("+new A.a8(p,new A.pj(),t.eK).bp(0,", ")+")"}}
A.pj.prototype={
$1(a){return a.a+": "+A.q(a.b)},
$S:60}
A.dP.prototype={
ew(){var s,r,q,p,o=this,n=o.d,m=t.N
n=A.bD(["total",n.b,"downloaded",n.a],m,t.S)
s=o.w
A:{if(s==null){r=null
break A}r=1000*s.a+s.b
break A}q=o.x
B:{if(q==null){p=null
break B}p=1000*q.a+q.b
break B}return A.bD(["name",o.a,"parameters",o.b,"priority",o.c,"progress",n,"active",o.e,"is_default",o.f,"has_explicit_subscription",o.r,"expires_at",r,"last_synced_at",p],m,t.X)}}
A.uJ.prototype={
$0(){var s=this,r=s.b,q=s.a,p=s.d,o=A.a5(r).h("@<1>").I(p.h("ac<0>")).h("a8<1,2>"),n=A.an(new A.a8(r,new A.uI(q,s.c,p),o),o.h("X.E"))
q.a=n},
$S:0}
A.uI.prototype={
$1(a){var s=this.b
return a.az(new A.uG(s,this.c),new A.uH(this.a,s),s.gfz())},
$S(){return this.c.h("ac<0>(C<0>)")}}
A.uG.prototype={
$1(a){return this.a.q(0,a)},
$S(){return this.b.h("~(0)")}}
A.uH.prototype={
$0(){var s=0,r=A.i(t.H),q=1,p=[],o=[],n=this,m,l,k,j,i
var $async$$0=A.d(function(a,b){if(a===1){p.push(b)
s=q}for(;;)switch(s){case 0:j=n.a
s=!j.b?2:3
break
case 2:j.b=!0
q=5
j=j.a
j.toString
s=8
return A.b(A.kL(j),$async$$0)
case 8:o.push(7)
s=6
break
case 5:q=4
i=p.pop()
m=A.E(i)
l=A.M(i)
n.b.ag(m,l)
o.push(7)
s=6
break
case 4:o=[1]
case 6:q=1
n.b.n()
s=o.pop()
break
case 7:case 3:return A.f(null,r)
case 1:return A.e(p.at(-1),r)}})
return A.h($async$$0,r)},
$S:3}
A.uK.prototype={
$0(){var s=this.a,r=s.a
if(r!=null&&!s.b)return A.kL(r)},
$S:33}
A.uL.prototype={
$0(){var s=this.a.a
if(s!=null)return A.Eh(s)},
$S:0}
A.uM.prototype={
$0(){var s=this.a.a
if(s!=null)return A.Em(s)},
$S:0}
A.uk.prototype={
$1(a){return a.u()},
$S:61}
A.uZ.prototype={
$1(a){var s=this.a
s.q(0,a)
s.n()},
$S(){return this.b.h("D(0)")}}
A.v_.prototype={
$2(a,b){var s
if(this.a.a)throw A.c(a)
else{s=this.b
s.ag(a,b)
s.n()}},
$S:7}
A.uY.prototype={
$0(){var s=0,r=A.i(t.H),q=this
var $async$$0=A.d(function(a,b){if(a===1)return A.e(b,r)
for(;;)switch(s){case 0:q.a.a=!0
s=2
return A.b(q.b,$async$$0)
case 2:return A.f(null,r)}})
return A.h($async$$0,r)},
$S:3}
A.pM.prototype={
$1(a){var s,r,q,p=this
try{if(p.a.$1(a)){p.b.L()
p.c.u()}}catch(q){s=A.E(q)
r=A.M(q)
p.b.b8(s,r)
p.c.u()}},
$S(){return this.d.h("~(0)")}}
A.pN.prototype={
$0(){var s=this.a
if((s.a.a&30)===0){s.a9(new A.bB(this.b))
this.c.u()}},
$S:1}
A.em.prototype={
q(a,b){var s,r,q,p,o,n,m,l,k,j,i,h=this,g=null,f="Stream is already closed"
for(s=J.aa(b),r=h.b,q=h.a.a,p=0;p<s.gk(b);){o=s.gk(b)-p
n=h.d
m=h.c
if(n!=null){l=Math.min(o,m)
k=p+l
if(p<0)A.r(A.ab(p,0,g,"start",g))
if(p>k)A.r(A.ab(k,p,g,"end",g))
n.hr(b,p,k)
if((h.c-=l)===0){m=B.e.gau(n.a)
j=n.a
j=J.cO(m,j.byteOffset,n.b*j.BYTES_PER_ELEMENT)
if((q.e&2)!==0)A.r(A.z(f))
q.bR(j)
h.d=null
h.c=4}p=k}else{l=Math.min(o,m)
i=J.zB(B.af.gau(r))
m=4-h.c
B.e.Y(i,m,m+l,b,p)
p+=l
if((h.c-=l)===0){m=h.c=r.getInt32(0,!0)-4
if(m<5){j=A.ec()
if((q.e&2)!==0)A.r(A.z(f))
q.eN(new A.e2("Invalid length for bson: "+m),j)}m=new A.bd(new Uint8Array(0),0)
m.hr(i,0,g)
h.d=m}}}},
ag(a,b){this.a.ag(a,b)},
n(){var s=this
if(s.d!=null||s.c!==4)s.a.ag(new A.e2("Pending data when stream was closed"),A.ec())
s.a.a.a_()},
$iah:1,
gk(a){return this.b}}
A.oV.prototype={
ar(){var s=0,r=A.i(t.H),q=this,p
var $async$ar=A.d(function(a,b){if(a===1)return A.e(b,r)
for(;;)switch(s){case 0:p=q.at
s=p!=null?2:3
break
case 2:q.w.n()
s=4
return A.b(A.Ae(new A.N(p.ar(),q.ch.n()),t.H,t.z),$async$ar)
case 4:case 3:q.y.n()
q.Q.n()
return A.f(null,r)}})
return A.h($async$ar,r)},
cO(){var s=0,r=A.i(t.H),q=1,p=[],o=[],n=this,m,l,k,j,i,h,g
var $async$cO=A.d(function(a,b){if(a===1){p.push(b)
s=q}for(;;)switch(s){case 0:g=A.zL()
n.at=g
m=g
q=2
s=5
return A.b(n.cn(),$async$cO)
case 5:h=n.c
l=h.a
k=h.b
j=null
if(k!=null)j=n.ck(m,k)
else if(l!=null)j=n.cZ(l,m)
h=t.M
i=A.u([],h)
if(j!=null)J.hN(i,A.ir(j,new A.p8(n,m),t.H,t.K))
if(l!=null)J.zz(i,A.u([n.cR(m,l),n.cY(l,m)],h))
s=6
return A.b(A.v9(i,t.H),$async$cO)
case 6:o.push(4)
s=3
break
case 2:o=[1]
case 3:q=1
i=n.as
i.a=B.a5
i.b.q(0,B.a5)
m.iQ()
s=o.pop()
break
case 4:return A.f(null,r)
case 1:return A.e(p.at(-1),r)}})
return A.h($async$cO,r)},
eu(){var s=0,r=A.i(t.g2),q,p=2,o=[],n=this,m,l,k,j,i,h,g
var $async$eu=A.d(function(a,b){if(a===1){o.push(b)
s=p}for(;;)switch(s){case 0:h=n.d.w
if(!((h==null?B.r:h) instanceof A.d9))throw A.c(B.b6)
m=n.c.a
if(m==null)throw A.c(B.z)
l=n.at
if(l==null||(l.a.a.a&30)!==0)throw A.c(B.z)
p=4
s=7
return A.b(n.ih(m,l),$async$eu)
case 7:k=b
h=v.G.BigInt(k)
q=new A.d0(h)
s=1
break
p=2
s=6
break
case 4:p=3
g=o.pop()
j=A.E(g)
if(A.eN(l,j))throw A.c(B.z)
throw g
s=6
break
case 3:s=2
break
case 6:case 1:return A.f(q,r)
case 2:return A.e(o.at(-1),r)}})
return A.h($async$eu,r)},
cn(){var s=0,r=A.i(t.N),q,p=this,o
var $async$cn=A.d(function(a,b){if(a===1)return A.e(b,r)
for(;;)switch(s){case 0:o=p.cx
s=o==null?3:5
break
case 3:s=6
return A.b(A.lo(p.b),$async$cn)
case 6:b=p.cx=b
s=4
break
case 5:b=o
case 4:q=b
s=1
break
case 1:return A.f(q,r)}})
return A.h($async$cn,r)},
cR(a,b){return this.ld(a,b)},
ld(a1,a2){var s=0,r=A.i(t.H),q,p=2,o=[],n=this,m,l,k,j,i,h,g,f,e,d,c,b,a,a0
var $async$cR=A.d(function(a3,a4){if(a3===1){o.push(a4)
s=p}for(;;)switch(s){case 0:g=a1.a.a,f=n.f,e=n.Q,d=n.ax,c=t.U,b=t.H
case 3:if(!((g.a&30)===0)){s=4
break}m=!1
p=6
l=null
s=9
return A.b(d.bJ(new A.oY(n,a1,a2),n.dJ(a1),c),$async$cR)
case 9:k=a4
l=k.a
m=!l
p=2
s=8
break
case 6:p=5
a0=o.pop()
j=A.E(a0)
i=A.M(a0)
if(A.eN(a1,j)){s=1
break}m=!0
h=A.Du(j)
f.P(B.i,"Sync error: "+A.q(h),j,i)
if(!e.gal())A.r(e.ak())
e.a2(new A.aK(null,null,j,null))
s=8
break
case 5:s=2
break
case 8:s=(g.a&30)===0&&m?10:11
break
case 10:s=12
return A.b(a1.b0(new A.oZ(n),b),$async$cR)
case 12:case 11:s=3
break
case 4:case 1:return A.f(q,r)
case 2:return A.e(o.at(-1),r)}})
return A.h($async$cR,r)},
ck(a,b){return this.la(a,b)},
la(a,b){var s=0,r=A.i(t.H),q=1,p=[],o=[],n=this,m,l,k
var $async$ck=A.d(function(c,d){if(c===1){p.push(d)
s=q}for(;;)switch(s){case 0:l=n.w
k=t.H
l=new A.bO(A.bA(A.yK(A.u([n.r,new A.a4(l,A.p(l).h("a4<1>"))],t.i3),k),"stream",t.K))
q=2
m=n.ay
case 5:s=7
return A.b(l.l(),$async$ck)
case 7:if(!d){s=6
break}l.gp()
s=8
return A.b(m.bJ(new A.oW(n,a,b),n.dJ(a),k),$async$ck)
case 8:s=5
break
case 6:o.push(4)
s=3
break
case 2:o=[1]
case 3:q=1
s=9
return A.b(l.u(),$async$ck)
case 9:s=o.pop()
break
case 4:return A.f(null,r)
case 1:return A.e(p.at(-1),r)}})
return A.h($async$ck,r)},
bU(a,b){return this.lb(a,b)},
lb(a8,a9){var s=0,r=A.i(t.H),q,p=2,o=[],n=[],m=this,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1,a2,a3,a4,a5,a6,a7
var $async$bU=A.d(function(b0,b1){if(b0===1){o.push(b1)
s=p}for(;;)switch(s){case 0:a6=null
f=a8.a.a,e=m.Q,d=m.c.a,c=d!=null,b=m.f,a=a9.goN(),a0=t.H,a1=m.b,a2=m.ch
case 3:if(!((f.a&30)===0)){s=4
break}l=!1
p=6
s=9
return A.b(A.lq(a1),$async$bU)
case 9:k=b1
s=k!=null?10:12
break
case 10:if(!e.gal())A.r(e.ak())
e.a2(new A.aK(null,!0,null,null))
a3=k.a
a4=a6
if(a3===(a4==null?null:a4.a)){b.P(B.i,"Potentially previously uploaded CRUD entries are still present in the upload queue. \n                Make sure to handle uploads and complete CRUD transactions or batches by calling and awaiting their [.complete()] method.\n                The next upload iteration will be delayed.",null,null)
a3=A.wz("Delaying due to previously encountered CRUD item.")
throw A.c(a3)}a6=k
s=13
return A.b(a8.b0(a,a0),$async$bU)
case 13:if(!e.gal())A.r(e.ak())
e.a2(new A.aK(null,null,null,B.v))
s=11
break
case 12:j=d
i=null
s=j!=null?14:15
break
case 14:i=j
s=16
return A.b(m.iw(i,a8),$async$bU)
case 16:l=b1
case 15:n=[4]
s=7
break
case 11:n.push(8)
s=7
break
case 6:p=5
a7=o.pop()
h=A.E(a7)
g=A.M(a7)
a6=null
if(A.eN(a8,h)){n=[1]
s=7
break}b.P(B.i,"Data upload error",h,g)
if(!e.gal())A.r(e.ak())
e.a2(new A.aK(null,null,null,h))
s=17
return A.b(m.dJ(a8),$async$bU)
case 17:if(c){a3=m.z
a3=(a3==null?null:a3.b)!==!0}else a3=!1
if(a3){n=[4]
s=7
break}b.P(B.i,"Caught exception when uploading. Upload will retry after a delay",h,g)
n.push(8)
s=7
break
case 5:n=[2]
case 7:p=2
if(!e.gal())A.r(e.ak())
e.a2(new A.aK(null,!1,null,null))
if((f.a&30)===0&&l){if(!a2.gal())A.r(a2.ak())
a2.a2(B.a4)}s=n.pop()
break
case 8:s=3
break
case 4:case 1:return A.f(q,r)
case 2:return A.e(o.at(-1),r)}})
return A.h($async$bU,r)},
cZ(a,b){return this.m8(a,b)},
m8(a,b){var s=0,r=A.i(t.H),q,p=2,o=[],n=this,m,l,k,j,i,h,g,f,e
var $async$cZ=A.d(function(c,d){if(c===1){o.push(d)
s=p}for(;;)switch(s){case 0:j=b.a.a,i=n.f,h=n.Q,g=n.ch
case 3:if(!((j.a&30)===0)){s=4
break}p=6
s=9
return A.b(n.iw(a,b),$async$cZ)
case 9:m=d
if(m){if(!g.gal())A.r(g.ak())
g.a2(B.a4)}if(!h.gal())A.r(h.ak())
h.a2(new A.aK(null,null,null,B.v))
s=1
break
p=2
s=8
break
case 6:p=5
e=o.pop()
l=A.E(e)
k=A.M(e)
if(A.eN(b,l)){s=1
break}i.P(B.i,"Error requesting checkpoint after crud upload",l,k)
if(!h.gal())A.r(h.ak())
h.a2(new A.aK(null,null,null,l))
s=10
return A.b(n.dJ(b),$async$cZ)
case 10:s=8
break
case 5:s=2
break
case 8:s=3
break
case 4:h.q(0,new A.aK(null,!1,null,null))
case 1:return A.f(q,r)
case 2:return A.e(o.at(-1),r)}})
return A.h($async$cZ,r)},
iw(a,b){return A.f_(this.b,new A.p7(this,a,b))},
eR(a,b){var s=a.r
s.m(0,"Authorization","Token "+b.b)
s.a7(0,this.CW)},
ih(a,b){return b.b0(new A.p6(this,a),t.N)},
b5(a,b,c,d){return this.m6(a,b,c,d)},
ig(a,b,c){return this.b5(a,b,c,null)},
m6(a,b,c,d){var s=0,r=A.i(t.N),q,p=this,o,n,m,l,k,j,i
var $async$b5=A.d(function(e,f){if(e===1)return A.e(f,r)
for(;;)switch(s){case 0:s=d==null?3:4
break
case 3:s=5
return A.b(p.cn(),$async$b5)
case 5:d=f
case 4:o=b.a.e9(d,c,a)
s=6
return A.b(t.cI.b(o)?o:A.bL(o,t.T),$async$b5)
case 6:n=f
if(n!=null){q=n
s=1
break}o=b.a
s=7
return A.b(o.cp(a),$async$b5)
case 7:m=f
if(m==null)throw A.c(A.v5("Not logged in"))
l=A.v2("POST",A.di(m.a).dr("sync/checkpoint-request"),a)
k=t.N
l.siM(B.h.fH(A.bD(["client_id",d,"checkpoint_request_id",c],k,k),null))
p.eR(l,m)
k=l.r
k.m(0,"Accept","application/json")
k.m(0,"Content-Type","application/json")
i=A
s=9
return A.b(p.y.ap(l),$async$b5)
case 9:s=8
return A.b(i.j3(f),$async$b5)
case 8:j=f
k=j.b
s=k===401?10:11
break
case 10:s=12
return A.b(o.c8(!0,a),$async$b5)
case 12:case 11:if(k===404)throw A.c(B.b5)
if(k!==200)throw A.c(A.xe(j))
q=A.ak(J.eX(J.eX(B.h.c5(A.w2(A.vQ(j.e)).aI(j.w),null),"data"),"checkpoint_request_id"))
s=1
break
case 1:return A.f(q,r)}})
return A.h($async$b5,r)},
bW(a,b){return this.lm(a,b)},
lm(a,b){var s=0,r=A.i(t.N),q,p=this,o,n,m,l,k
var $async$bW=A.d(function(c,d){if(c===1)return A.e(d,r)
for(;;)switch(s){case 0:m=t.J
s=3
return A.b(b.b0(new A.p_(a),m),$async$bW)
case 3:l=d
if(l==null)throw A.c(A.v5("Not logged in"))
k=A
s=4
return A.b(p.cn(),$async$bW)
case 4:o=k.q(d)
s=5
return A.b(b.b0(new A.p0(p,A.di(l.a).dr("write-checkpoint2.json?client_id="+o),l),t.b),$async$bW)
case 5:n=d
o=n.b
s=o===401?6:7
break
case 6:s=8
return A.b(b.b0(new A.p1(a),m),$async$bW)
case 8:case 7:if(o!==200)throw A.c(A.xe(n))
q=A.ak(J.eX(J.eX(B.h.c5(A.w2(A.vQ(n.e)).aI(n.w),null),"data"),"write_checkpoint"))
s=1
break
case 1:return A.f(q,r)}})
return A.h($async$bW,r)},
dT(a,b){return this.md(a,b)},
md(a,b){var s=0,r=A.i(t.U),q,p=this,o,n
var $async$dT=A.d(function(c,d){if(c===1)return A.e(d,r)
for(;;)switch(s){case 0:n=p.f
n.P(B.m,"Starting Rust sync iteration",null,null)
s=3
return A.b(new A.qu(p,a,b).kD(),$async$dT)
case 3:o=d
n.P(B.m,"Ending Rust sync iteration. Immediate restart: "+o.a,null,null)
q=o
s=1
break
case 1:return A.f(q,r)}})
return A.h($async$dT,r)},
bZ(a,b,c){return this.lU(a,b,c)},
lU(a,b,c){var s=0,r=A.i(t.n),q,p=this,o,n,m,l,k,j
var $async$bZ=A.d(function(d,e){if(d===1)return A.e(e,r)
for(;;)switch(s){case 0:l=b.a
s=3
return A.b(l.cp(c),$async$bZ)
case 3:k=e
if(k==null)throw A.c(A.v5("Not logged in"))
o=A.v2("POST",A.di(k.a).dr("sync/stream"),c)
p.eR(o,k)
n=o.r
n.m(0,"Content-Type","application/json")
n.m(0,"Accept","application/vnd.powersync.bson-stream;q=0.9,application/x-ndjson;q=0.8")
o.siM(B.h.fH(a,null))
s=4
return A.b(p.y.ap(o),$async$bZ)
case 4:m=e
n=m.b
s=n===401?5:6
break
case 5:s=7
return A.b(l.c8(!0,c),$async$bZ)
case 7:case 6:s=n!==200?8:9
break
case 8:j=A
s=10
return A.b(A.pc(m),$async$bZ)
case 10:throw j.c(e)
case 9:q=m
s=1
break
case 1:return A.f(q,r)}})
return A.h($async$bZ,r)},
cY(a,b){return this.m5(a,b)},
m5(a,b){var s=0,r=A.i(t.H),q,p=2,o=[],n=this,m,l,k,j,i,h,g,f,e,d
var $async$cY=A.d(function(c,a0){if(c===1){o.push(a0)
s=p}for(;;)switch(s){case 0:e={}
e.a=null
A:{k=n.d.w
if(k==null)k=B.r
j=k instanceof A.d9
i=j?k.a:null
if(j){e.a=i
break A}s=1
break}j=b.a.a,h=n.f,g=t.H
case 3:if(!((j.a&30)===0)){s=4
break}p=6
s=9
return A.b(b.b0(new A.p4(e,n,a),g),$async$cY)
case 9:p=2
s=8
break
case 6:p=5
d=o.pop()
m=A.E(d)
l=A.M(d)
if((j.a&30)!==0){s=1
break}h.P(B.i,"Error retrying checkpoint request",m,l)
s=10
return A.b(n.hJ(b,e.a),$async$cY)
case 10:s=8
break
case 5:s=2
break
case 8:s=3
break
case 4:case 1:return A.f(q,r)
case 2:return A.e(o.at(-1),r)}})
return A.h($async$cY,r)},
bi(a,b,c){return this.m4(a,b,c)},
m4(a,b,c){var s=0,r=A.i(t.H),q,p=this,o,n,m,l,k,j,i
var $async$bi=A.d(function(d,e){if(d===1)return A.e(e,r)
for(;;)switch(s){case 0:k=new A.p2(p,c)
j=p.as
s=3
return A.b(j.h9(c,!1),$async$bi)
case 3:s=4
return A.b(k.$0(),$async$bi)
case 4:o=e
n=A.vR(b)
c.J(n.b)
s=5
return A.b(n.a,$async$bi)
case 5:i=o==null
if(i)e=i
else{s=6
break}s=7
break
case 6:i=o
s=8
return A.b(k.$0(),$async$bi)
case 8:e=!i.D(0,e)
case 7:if(e){s=1
break}k=p.z
m=k==null?null:k.r
k=!1
if(m!=null){l=m.a>=o.a
k=l}if(k){s=1
break}s=9
return A.b(j.h9(c,!1),$async$bi)
case 9:p.f.P(B.p,"Retry checkpoint request "+o.j(0),null,null)
s=10
return A.b(p.ig(c,a,v.G.String(o.a)),$async$bi)
case 10:case 1:return A.f(q,r)}})
return A.h($async$bi,r)},
hJ(a,b){return a.b0(new A.oX(this,b),t.H)},
dJ(a){return this.hJ(a,null)},
dV(){var s=0,r=A.i(t.y),q,p=this
var $async$dV=A.d(function(a,b){if(a===1)return A.e(b,r)
for(;;)switch(s){case 0:if(p.c.b!=null){q=!0
s=1
break}s=3
return A.b(A.lp(p.b),$async$dV)
case 3:q=!b
s=1
break
case 1:return A.f(q,r)}})
return A.h($async$dV,r)}}
A.p8.prototype={
$2(a,b){if(A.eN(this.b,a))return
this.a.f.P(B.i,"Error in crud upload loop",a,b)},
$S:7}
A.oY.prototype={
$0(){return this.a.dT(this.b,this.c)},
$S:62}
A.oZ.prototype={
$1(a){var s=this.a,r=s.d.d,q=A.vR(r==null?B.u:r),p=q.b
a.J(p)
s.as.c.a.J(p)
return q.a},
$S:20}
A.oW.prototype={
$0(){return this.a.bU(this.b,this.c)},
$S:3}
A.p7.prototype={
$0(){var s,r,q=this.a,p=q.d.w
if(p==null)p=B.r
s=this.b
r=this.c
if(p instanceof A.fr)return q.bW(s,r)
else return q.ih(s,r)},
$S:64}
A.p6.prototype={
$1(a){return this.jS(a)},
jS(a){var s=0,r=A.i(t.N),q,p=this,o,n,m,l
var $async$$1=A.d(function(b,c){if(b===1)return A.e(c,r)
for(;;)switch(s){case 0:o=p.a
s=3
return A.b(o.as.oQ(a),$async$$1)
case 3:n=o
m=a
l=p.b
s=5
return A.b(A.v3(o.b,new A.p5(),a,t.N),$async$$1)
case 5:s=4
return A.b(n.ig(m,l,c),$async$$1)
case 4:q=c
s=1
break
case 1:return A.f(q,r)}})
return A.h($async$$1,r)},
$S:65}
A.p5.prototype={
$1(a){return A.o2(a)},
$S:37}
A.p_.prototype={
$1(a){return this.a.a.cp(a)},
$S:28}
A.p0.prototype={
$1(a){return this.jQ(a)},
jQ(a){var s=0,r=A.i(t.b),q,p=this,o,n,m
var $async$$1=A.d(function(b,c){if(b===1)return A.e(c,r)
for(;;)switch(s){case 0:o=A.v2("GET",p.b,a)
n=p.a
n.eR(o,p.c)
o.r.m(0,"Accept","application/json")
m=A
s=4
return A.b(n.y.ap(o),$async$$1)
case 4:s=3
return A.b(m.j3(c),$async$$1)
case 3:q=c
s=1
break
case 1:return A.f(q,r)}})
return A.h($async$$1,r)},
$S:67}
A.p1.prototype={
$1(a){return this.a.a.c8(!0,a)},
$S:28}
A.p4.prototype={
$1(a){return this.b.bi(this.c,this.a.a,a)},
$S:20}
A.p2.prototype={
$0(){return A.v3(this.a.b,new A.p3(),this.b,t.fo)},
$S:68}
A.p3.prototype={
$1(a){return this.jR(a)},
jR(a){var s=0,r=A.i(t.fo),q,p
var $async$$1=A.d(function(b,c){if(b===1)return A.e(c,r)
for(;;)switch(s){case 0:s=3
return A.b(A.d6(a,"current",null),$async$$1)
case 3:p=c
q=p==null?null:new A.d0(v.G.BigInt(p))
s=1
break
case 1:return A.f(q,r)}})
return A.h($async$$1,r)},
$S:69}
A.oX.prototype={
$1(a){var s,r=this.b
if(r==null){r=this.a.d.d
if(r==null)r=B.u}s=A.vR(r)
a.J(s.b)
return s.a},
$S:20}
A.tY.prototype={
$0(){var s,r,q=this.b
if((q.a.a&30)===0){s=this.a
r=s.a
if(r!=null)r.u()
s.a=null
q.L()}},
$S:0}
A.qu.prototype={
hL(a){var s=this.a.e,r=A.a5(s).h("a8<1,a3<j,@>>")
s=A.an(new A.a8(s,new A.qv(),r),r.h("X.E"))
return s},
kD(){return this.b.b0(new A.qB(this),t.U)},
dU(){var s=0,r=A.i(t.ks),q,p=this,o,n,m,l
var $async$dU=A.d(function(a,b){if(a===1)return A.e(b,r)
for(;;)switch(s){case 0:o=t.N
n=A.T(o,t.z)
m=p.a
l=m.d
n.m(0,"app_metadata",A.AS(l))
n.m(0,"parameters",A.AT(l))
n.m(0,"schema",B.h.aI(m.a))
n.m(0,"include_defaults",l.f!==!1)
n.m(0,"active_streams",p.hL(m.e))
m=l.w
n.m(0,"checkpoint_mode",(m==null?B.r:m) instanceof A.d9?"requests":"legacy")
if(l.x)n.m(0,"diagnostics",A.T(o,t.X))
s=3
return A.b(p.bh("start",B.h.b9(n)),$async$dU)
case 3:q=b
s=1
break
case 1:return A.f(q,r)}})
return A.h($async$dU,r)},
d_(a,b){return this.me(a,b)},
me(a,b){var s=0,r=A.i(t.H),q=1,p=[],o=[],n=this,m,l,k,j,i,h,g
var $async$d_=A.d(function(c,d){if(c===1){p.push(d)
s=q}for(;;)switch(s){case 0:q=3
j=n.a
i=b.a.a
s=6
return A.b(j.b5(i,n.c,a.b,a.a),$async$d_)
case 6:m=d
s=7
return A.b(A.v3(j.b,new A.qA(m),i,t.H),$async$d_)
case 7:j=j.as
i=new A.en(new A.fV(null))
j.a=i
j.b.q(0,i)
o.push(5)
s=4
break
case 3:q=2
g=p.pop()
l=A.E(g)
k=A.M(g)
if((b.a.a.a&30)===0){j=n.a
j.ch.q(0,new A.f3(l,k))
j=j.as
i=new A.en(new A.ii(l,k))
j.a=i
j.b.q(0,i)}o.push(5)
s=4
break
case 2:o=[1]
case 4:q=1
b.iQ()
b.ar()
s=o.pop()
break
case 5:return A.f(null,r)
case 1:return A.e(p.at(-1),r)}})
return A.h($async$d_,r)},
lZ(a,b){return A.Ep(this.a.bZ(a,this.c,b),t.n).mK(new A.qz(),t.o)},
aN(a){return this.lr(a)},
lr(b5){var s=0,r=A.i(t.U),q,p=2,o=[],n=[],m=this,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,b0,b1,b2,b3,b4
var $async$aN=A.d(function(b6,b7){if(b6===1){o.push(b7)
s=p}for(;;)switch(s){case 0:b3=!1
p=4
a2=new A.bO(A.bA(b5,"stream",t.K))
p=8
a3=t.Y,a4=m.a,a5=a4.f,a6=m.b.a.a,a7=t.p,a4=a4.w
case 11:s=13
return A.b(a2.l(),$async$aN)
case 13:if(!b7){s=12
break}l=a2.gp()
if((a6.a&30)!==0){s=12
break}k=null
j=l
i=null
h=!1
s=j instanceof A.dO?15:16
break
case 15:s=17
return A.b(m.bh("connection",l.b),$async$aN)
case 17:k=b7
s=14
break
case 16:g=null
if(j instanceof A.cu){if(h)a8=i
else{h=!0
a9=j.a
i=a9
a8=a9}a8=a7.b(a8)
if(a8){if(h)b0=i
else{h=!0
a9=j.a
i=a9
b0=a9}g=a7.a(b0)}}else a8=!1
s=a8?18:19
break
case 18:if(!m.d){a8=a4.b
if(a8>=4)A.r(a4.aq())
if((a8&1)!==0)a4.a2(null)
else if((a8&3)===0){a8=a4.bV()
b0=new A.bv(null)
b1=a8.c
if(b1==null)a8.b=a8.c=b0
else{b1.sbs(b0)
a8.c=b0}}m.d=!0}s=20
return A.b(m.bh("line_binary",g),$async$aN)
case 20:k=b7
s=14
break
case 19:f=null
a8=j instanceof A.cu
if(a8){if(h)b0=i
else{h=!0
a9=j.a
i=a9
b0=a9}A.ak(b0)
if(h)b0=i
else{h=!0
a9=j.a
i=a9
b0=a9}f=A.ak(b0)}s=a8?21:22
break
case 21:if(!m.d){a8=a4.b
if(a8>=4)A.r(a4.aq())
if((a8&1)!==0)a4.a2(null)
else if((a8&3)===0){a8=a4.bV()
b0=new A.bv(null)
b1=a8.c
if(b1==null)a8.b=a8.c=b0
else{b1.sbs(b0)
a8.c=b0}}m.d=!0}s=23
return A.b(m.bh("line_text",f),$async$aN)
case 23:k=b7
s=14
break
case 22:s=j instanceof A.fU?24:25
break
case 24:s=26
return A.b(m.fh("completed_upload"),$async$aN)
case 26:k=b7
s=14
break
case 25:s=j instanceof A.fP?27:28
break
case 27:s=29
return A.b(m.fh("refreshed_token"),$async$aN)
case 29:k=b7
s=14
break
case 28:e=null
a8=j instanceof A.fi
if(a8)e=j.a
s=a8?30:31
break
case 30:s=32
return A.b(m.bh("update_subscriptions",B.h.b9(m.hL(e))),$async$aN)
case 32:k=b7
s=14
break
case 31:d=null
c=null
a8=j instanceof A.f3
if(a8){d=j.a
c=j.b}if(a8)A.ik(d,c)
case 14:a8=J.a0(k)
case 33:if(!a8.l()){s=34
break}b=a8.gp()
a=b
if(a instanceof A.dR){a5.P(B.i,"Received EstablishSyncStream connection while already connected.",null,null)
s=33
break}a0=null
b0=a instanceof A.dM
if(b0)a0=a.a
if(b0){b3=a0
n=[7]
s=9
break}a1=null
b0=a3.b(a)
if(b0)a1=a
s=b0?35:36
break
case 35:s=37
return A.b(m.bX(a1),$async$aN)
case 37:case 36:s=33
break
case 34:s=11
break
case 12:n.push(10)
s=9
break
case 8:n=[4]
case 9:p=4
s=38
return A.b(a2.u(),$async$aN)
case 38:s=n.pop()
break
case 10:case 7:p=2
s=6
break
case 4:p=3
b4=o.pop()
if(A.E(b4) instanceof A.cv){if((m.b.a.a.a&30)===0)throw b4}else throw b4
s=6
break
case 3:s=2
break
case 6:q=new A.hn(b3)
s=1
break
case 1:return A.f(q,r)
case 2:return A.e(o.at(-1),r)}})
return A.h($async$aN,r)},
d0(){var s=0,r=A.i(t.H),q=this,p,o,n,m
var $async$d0=A.d(function(a,b){if(a===1)return A.e(b,r)
for(;;)switch(s){case 0:m=J
s=2
return A.b(q.fh("stop"),$async$d0)
case 2:p=m.a0(b),o=t.Y
case 3:if(!p.l()){s=4
break}n=p.gp()
s=o.b(n)?5:6
break
case 5:s=7
return A.b(q.bX(n),$async$d0)
case 7:case 6:s=3
break
case 4:return A.f(null,r)}})
return A.h($async$d0,r)},
bh(a,b){return this.ly(a,b)},
fh(a){return this.bh(a,null)},
ly(a,b){var s=0,r=A.i(t.ks),q,p=this,o,n,m,l
var $async$bh=A.d(function(c,d){if(c===1)return A.e(d,r)
for(;;)switch(s){case 0:n=J
m=t.j
l=B.h
s=3
return A.b(A.lm(p.a.b,a,b),$async$bh)
case 3:o=n.zC(m.a(l.aI(d)),t.f)
q=new A.a8(o,A.E5(),o.$ti.h("a8<y.E,ar>"))
s=1
break
case 1:return A.f(q,r)}})
return A.h($async$bh,r)},
bX(a){return this.lq(a)},
lq(a){var s=0,r=A.i(t.H),q=this,p,o,n,m,l,k,j,i
var $async$bX=A.d(function(b,c){if(b===1)return A.e(c,r)
for(;;)switch(s){case 0:p=a instanceof A.ft
if(p){o=a.a
n=a.b}else{o=null
n=null}if(p){switch(o){case"DEBUG":p=B.p
break
case"INFO":p=B.m
break
default:p=B.i
break}q.a.f.oe(p,n)
s=2
break}p=a instanceof A.fS
m=p?a.a:null
if(p){p=q.a
p.z=m
p.Q.q(0,new A.aK(m,null,null,null))
s=2
break}p={}
p.a=null
l=a instanceof A.ff
if(l)p.a=a.a
s=l?3:4
break
case 3:k=q.b.b0(new A.qw(p,q),t.J)
s=p.a?5:7
break
case 5:s=8
return A.b(k,$async$bX)
case 8:s=6
break
case 7:k.bc(new A.qx(q),new A.qy(q),t.P)
case 6:s=2
break
case 4:if(a instanceof A.fb){q.a.Q.q(0,new A.aK(null,null,B.v,null))
s=2
break}s=a instanceof A.f2?9:10
break
case 9:p=q.a
s=11
return A.b(p.dV(),$async$bX)
case 11:if(!c){p.f.P(B.i,u.l,null,null)
p.Q.q(0,new A.aK(null,null,new A.aW(u.l),null))}s=2
break
case 10:p=a instanceof A.fj
j=p?a.a:null
if(p){q.a.x.q(0,B.h.b9(j))
s=2
break}p=a instanceof A.fQ
i=p?a.a:null
if(p)q.a.f.P(B.i,"Unknown instruction: "+A.q(i),null,null)
case 2:return A.f(null,r)}})
return A.h($async$bX,r)}}
A.qv.prototype={
$1(a){return A.bD(["name",a.a,"params",B.h.aI(a.b)],t.N,t.z)},
$S:70}
A.qB.prototype={
$1(a){return this.jY(a)},
jY(b5){var s=0,r=A.i(t.U),q,p=2,o=[],n=[],m=this,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,b0,b1,b2,b3,b4
var $async$$1=A.d(function(b6,b7){if(b6===1){o.push(b7)
s=p}for(;;)switch(s){case 0:b0=null
b1=null
p=4
b3=e=m.a
b4=J
s=7
return A.b(e.dU(),$async$$1)
case 7:b3,d=b4.a0(b7),c=t.Y,b=e.a.ch,a=A.p(b).h("ao<1>"),a0=t.o,a1=t.fu,a2=t.D,a3=t.h,a4=t.A
case 8:if(!d.l()){s=9
break}l=d.gp()
k=l
j=null
i=null
a5=k instanceof A.dR
if(a5){j=k.a
i=k.b}if(a5){b0=A.yK(A.u([e.lZ(j,b5),new A.ao(b,a)],a1),a0)
if(i!=null){a5=$.o
a6=new A.a9(new A.l(a5,a2),a3)
a7=A.bp(a4)
a8=new A.hO(a6,a7,new A.a9(new A.l(a5,a2),a3))
a7.q(0,a6)
b1=a8
h=a8
e.d_(i,h)}s=8
break}if(k instanceof A.dM){q=B.ah
n=[1]
s=5
break}g=null
a5=c.b(k)
if(a5)g=k
s=a5?10:11
break
case 10:s=12
return A.b(e.bX(g),$async$$1)
case 12:case 11:s=8
break
case 9:if(b0==null){q=B.ah
n=[1]
s=5
break}s=13
return A.b(e.aN(b0),$async$$1)
case 13:e=b7
q=e
n=[1]
s=5
break
n.push(6)
s=5
break
case 4:p=3
b2=o.pop()
f=A.E(b2)
e=m.a
if(!A.eN(e.b,f))e.a.Q.q(0,new A.aK(null,null,f,null))
throw b2
n.push(6)
s=5
break
case 3:n=[2]
case 5:p=2
e=b1
e=e==null?null:e.ar()
s=14
return A.b(e instanceof A.l?e:A.bL(e,t.H),$async$$1)
case 14:e=m.a
d=e.a.as
d.c=new A.a9(new A.l($.o,t.D),t.h)
d.a=B.D
d.b.q(0,B.D)
s=15
return A.b(e.d0(),$async$$1)
case 15:s=n.pop()
break
case 6:case 1:return A.f(q,r)
case 2:return A.e(o.at(-1),r)}})
return A.h($async$$1,r)},
$S:71}
A.qA.prototype={
$1(a){return A.d6(a,"seed",this.a)},
$S:72}
A.qz.prototype={
$1(a){return this.jX(a)},
jX(a){var $async$$1=A.d(function(b,c){switch(b){case 2:n=q
s=n.pop()
break
case 1:o.push(c)
s=p}for(;;)switch(s){case 0:s=3
q=[1]
return A.kF(A.xF(B.b7),$async$$1,r)
case 3:m=a.w
if(a.e.i(0,"content-type")==="application/vnd.powersync.bson-stream")m=new A.c9(A.Eq(),m,t.jB)
else m=B.aX.bk(B.aE.bk(m))
s=4
q=[1]
return A.kF(A.BQ(new A.aL(A.Er(),m,m.$ti.h("aL<C.T,aR>"))),$async$$1,r)
case 4:s=5
q=[1]
return A.kF(A.xF(B.b8),$async$$1,r)
case 5:case 1:return A.kF(null,0,r)
case 2:return A.kF(o.at(-1),1,r)}})
var s=0,r=A.D7($async$$1,t.o),q,p=2,o=[],n=[],m
return A.Dr(r)},
$S:73}
A.qw.prototype={
$1(a){return this.b.c.a.c8(this.a.a,a)},
$S:28}
A.qx.prototype={
$1(a){var s=this.a
if((s.b.a.a.a&30)===0)s.a.ch.q(0,B.b0)},
$S:74}
A.qy.prototype={
$2(a,b){var s=this.a
if(!A.eN(s.b,a))s.a.f.P(B.i,"Could not prefetch credentials",a,b)},
$S:7}
A.dO.prototype={
aE(){return"ConnectionEvent."+this.b},
$iaR:1}
A.cu.prototype={$iaR:1}
A.fU.prototype={$iaR:1}
A.fP.prototype={$iaR:1}
A.fi.prototype={$iaR:1}
A.f3.prototype={$iaR:1}
A.e5.prototype={
ap(a){return this.ki(a)},
ki(a){var s=0,r=A.i(t.n),q,p=this,o,n,m,l,k,j
var $async$ap=A.d(function(b,c){if(b===1)return A.e(c,r)
for(;;)switch(s){case 0:a.hl()
k=t.a
j=B.e
s=3
return A.b(new A.cQ(A.xb(a.y,t.f4)).h5(),$async$ap)
case 3:o=k.a(j.gau(c))
n=p.b++
m=p.a.dC({r:0,i:n,u:a.b.j(0),m:a.a,h:B.h.b9(a.r),b:o})
a.cx.J(new A.oo(p,n))
s=4
return A.b(m,$async$ap)
case 4:l=c
n=A.C6(p,n).c
q=A.B4(new A.a4(n,A.p(n).h("a4<1>")),l.s,null,A.Aj(l),!1,!0,null,a)
s=1
break
case 1:return A.f(q,r)}})
return A.h($async$ap,r)},
hi(a,b){this.a.y.postMessage({type:"abortHttpRequest",payload:{r:b,i:a}})}}
A.oo.prototype={
$0(){return this.a.hi(this.b,!1)},
$S:0}
A.kk.prototype={
kR(a,b){var s=this.c
s.f=s.d=this.gny()
s.r=new A.td(this)},
eb(){var s=0,r=A.i(t.H),q=1,p=[],o=[],n=this,m,l,k,j,i,h
var $async$eb=A.d(function(a,b){if(a===1){p.push(b)
s=q}for(;;)switch(s){case 0:n.d=!0
q=3
s=6
return A.b(n.a.a.er(n.b),$async$eb)
case 6:m=b
j=n.c
if(m!=null)j.q(0,A.aU(m,0,null))
else j.n()
o.push(5)
s=4
break
case 3:q=2
h=p.pop()
l=A.E(h)
k=A.M(h)
j=n.c
j.ag(l,k)
j.n()
o.push(5)
s=4
break
case 2:o=[1]
case 4:q=1
n.d=!1
n.j_()
s=o.pop()
break
case 5:return A.f(null,r)
case 1:return A.e(p.at(-1),r)}})
return A.h($async$eb,r)},
j_(){var s,r,q=!1
if(!this.d){s=this.c
r=s.b
if((r&1)!==0)if((r&4)===0){q=s.ga6().e
q=(q&4)===0}}if(q)this.eb()}}
A.td.prototype={
$0(){var s=this.a
return s.a.hi(s.b,!0)},
$S:0}
A.vm.prototype={
$2(a,b){this.a.r.m(0,a,b)
return b},
$S:34}
A.vE.prototype={
n(){var s,r=this
if(!r.a){r.a=!0
s=r.c
if(s!=null)s.u()
r.iC(!1)}},
iC(a){var s,r=this.b
if((r.a.a&30)===0){if(a){s=this.c
if(s!=null)s.u()}r.L()}}}
A.pk.prototype={
m_(a,b,c,d,e){var s=this.a.cB(a,new A.pl(a))
s.oy(e,b,c,d)
return s}}
A.pl.prototype={
$0(){return A.Ba(this.a)},
$S:75}
A.ck.prototype={
kF(a,b){var s=this,r=A.Bm(a,new A.lV(s))
s.a=r
r.c.a.J(s.goh())
s.d=$.cN().f8().O(new A.lW(s))},
fX(){var s=this,r=s.d
if(r!=null)r.u()
r=s.c
if(r!=null)r.e.q(0,new A.hr(s))
s.c=null}}
A.lV.prototype={
$3(a,b,c){return this.jI(a,b,c)},
jI(a3,a4,a5){var s=0,r=A.i(t.k0),q,p=this,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1,a2
var $async$$3=A.d(function(a6,a7){if(a6===1)return A.e(a7,r)
for(;;)switch(s){case 0:case 3:switch(a3.a){case 1:s=5
break
case 3:s=6
break
case 2:s=7
break
case 7:s=8
break
default:s=9
break}break
case 5:A.Q(a4)
o=p.a
n=o.a
n===$&&A.P()
m=a4.lockName
if(!n.f){n.f=!0
A.q9(m).oc(n.gaG(),t.H)}n=A.ig(0,a4.crudThrottleTimeMs)
l=a4.retryDelayMs
A:{if(l==null){m=null
break A}m=A.ig(0,l)
break A}k=a4.syncParamsEncoded
B:{if(k==null){j=null
break B}j=t.f.a(B.h.c5(k,null))
break B}i=a4.appMetadataEncoded
C:{if(i==null){h=null
break C}h=t.N
h=A.wN(t.ea.a(B.h.c5(i,null)),h,h)
break C}g=J.A(a4.customHttpClient,!0)?new A.lU(o):null
f=a4.checkpointModeRequestsDelay
D:{if(f==null){e=B.r
break D}e=new A.d9(A.ig(f,0))
break D}d=a4.diagnostics
if(d==null)d=!1
c=a4.hasAuthenticator
if(c==null)c=!0
b=a4.hasUploader
if(b==null)b=!0
o.e=c?new A.oe(o.a):null
o.f=b?new A.j2(o.a):null
a=a4.databaseName
a0=a4.schemaJson
a1=a4.subscriptions
a1=a1==null?null:A.xm(a1)
if(a1==null)a1=B.bt
o.c=o.b.m_(a,new A.fN(h,j,n,m,B.ao,null,g,e,d),a0,a1,o)
q=new A.N({},null)
s=1
break
case 6:o=p.a
n=o.c
if(n!=null)n.e.q(0,new A.h6(o))
o.c=null
q=new A.N({},null)
s=1
break
case 7:o=p.a
n=o.c
if(n!=null){m=A.xm(A.Q(a4))
n.e.q(0,new A.h3(o,m))}q=new A.N({},null)
s=1
break
case 8:a2=A
s=10
return A.b(p.a.c.f.eu(),$async$$3)
case 10:q=new a2.N(a7.a,null)
s=1
break
case 9:throw A.c(A.z("Unexpected message type "+a3.j(0)))
case 4:case 1:return A.f(q,r)}})
return A.h($async$$3,r)},
$S:76}
A.lU.prototype={
$0(){var s=this.a.a
s===$&&A.P()
return new A.e5(s)},
$S:77}
A.lW.prototype={
$1(a){var s="["+a.d+"] "+a.a.a+": "+a.e.j(0)+": "+a.b,r=a.r
if(r!=null)s=s+"\n"+A.q(r)
r=a.w
if(r!=null)s=s+"\n"+r.j(0)
r=this.a.a
r===$&&A.P()
r.y.postMessage({type:"logEvent",payload:s.charCodeAt(0)==0?s:s})},
$S:36}
A.ee.prototype={
kK(a){var s=this.e
this.d.q(0,new A.a4(s,A.p(s).h("a4<1>")))
A.Af(new A.pi(this),t.P)},
ci(){var s=0,r=A.i(t.H),q=this,p,o,n
var $async$ci=A.d(function(a,b){if(a===1)return A.e(b,r)
for(;;)switch(s){case 0:n=$.cN()
n.P(B.m,"Remote database closed, finding a new client",null,null)
p=q.f
p=p==null?null:p.ar()
s=2
return A.b(p instanceof A.l?p:A.bL(p,t.H),$async$ci)
case 2:q.f=null
s=3
return A.b(q.eX(),$async$ci)
case 3:o=b
s=o==null?4:6
break
case 4:n.P(B.m,"No client remains",null,null)
s=5
break
case 6:s=7
return A.b(q.c0(o),$async$ci)
case 7:case 5:return A.f(null,r)}})
return A.h($async$ci,r)},
jr(){var s,r,q=this,p=q.y,o=A.Av(p,A.a5(p).c)
p=q.x
s=A.wI(new A.bX(p,A.p(p).h("bX<2>")),t.E)
if(!B.aZ.bG(o,s)){$.cN().P(B.m,"Subscriptions across tabs have changed, checking whether a reconnect is necessary",null,null)
p=A.an(s,A.p(s).c)
q.y=p
r=q.f
if(r!=null){r.e=p
r=r.ch
if(r.d!=null)r.q(0,new A.fi(p))}}},
eX(){return this.l1()},
l1(){var s=0,r=A.i(t.gO),q,p=this,o,n,m,l,k,j,i,h,g
var $async$eX=A.d(function(a,b){if(a===1)return A.e(b,r)
for(;;)switch(s){case 0:j={}
i=p.x
h=A.p(i).h("b2<1>")
g=A.an(new A.b2(i,h),h.h("m.E"))
i=g.length
if(i===0){q=null
s=1
break}h=new A.l($.o,t.iB)
o=new A.a9(h,t.if)
j.a=i
for(n=t.P,m=0;m<g.length;g.length===i||(0,A.a6)(g),++m){l=g[m]
k=l.a
k===$&&A.P()
k.eq().aK(new A.pd(j,o,l),n).oH(B.u,new A.pe(j,l,o))}q=h
s=1
break
case 1:return A.f(q,r)}})
return A.h($async$eX,r)},
c0(a){return this.m7(a)},
m7(a6){var s=0,r=A.i(t.H),q=this,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1,a2,a3,a4,a5
var $async$c0=A.d(function(a7,a8){if(a7===1)return A.e(a8,r)
for(;;)switch(s){case 0:a5=$.cN()
a5.P(B.m,"Sync setup: Requesting database",null,null)
p=a6.a
p===$&&A.P()
s=2
return A.b(p.ev(),$async$c0)
case 2:o=a8
a5.P(B.m,"Sync setup: Connecting to endpoint",null,null)
p=o.databasePort
s=3
return A.b(A.qd(new A.kh(o.databaseName,p,o.lockName)),$async$c0)
case 3:n=a8
a5.P(B.m,"Sync setup: Has database, starting sync!",null,null)
q.w=a6
p=t.P
n.a.c.a.aK(new A.pf(a6),p)
m=A.u(["ps_crud"],t.s)
A.Ei(new A.dr(t.hV))
l=n.d
k=A.Bd(m).bk(l)
l=q.b.c
if(l==null)l=B.G
j=A.Be(k,l,new A.I(B.bC))
l=q.x
l=A.wI(new A.bX(l,A.p(l).h("bX<2>")),t.E)
l=A.an(l,A.p(l).c)
q.y=l
i=q.c
h=a6.e
g=a6.f
f=q.b
e=q.a
p=A.bH(null,null,null,null,!1,p)
d=t.N
c=A.c2(!1,d)
b=A.c2(!1,t.k4)
a=A.c2(!1,t.hi)
a0=$.o
a1=A.c2(!1,t.o)
a2=f.r
a2=a2==null?null:a2.$0()
if(a2==null){a6=$.o.i(0,B.bE)
a2=a6==null?null:t.dF.a(a6).$0()
if(a2==null)a2=new A.i2(A.u([],t.kG))}a3=A.q9("sync-"+e)
e=A.q9("crud-"+e)
d=A.bD(["X-User-Agent","powersync-dart-core/2.6.2 Dart (flutter-web)"],d,d)
a4=new A.oV(i,n,new A.nC(h,g),f,l,a5,j,p,c,a2,b,new A.lF(B.D,a,new A.a9(new A.l(a0,t.D),t.h)),a3,e,a1,d)
q.f=a4
new A.ao(b,A.p(b).h("ao<1>")).O(new A.pg(q))
new A.ao(c,A.p(c).h("ao<1>")).O(new A.ph(q))
a4.cO()
return A.f(null,r)}})
return A.h($async$c0,r)},
oy(a,b,c,d){var s,r,q,p=a.e!=null,o=a.f!=null
for(s=this.x,s=new A.d2(s,s.r,s.e);s.l();){r=s.d
if(r===a)continue
q=r.e
r=r.f
if(p!==(q!=null)||o!==(r!=null))throw A.c(A.z("Different tabs connecting in different modes (download-only / upload-only / full) is not supported"))}this.e.q(0,new A.fY(a,b,c,d))}}
A.pi.prototype={
$0(){var s=0,r=A.i(t.P),q=1,p=[],o=[],n=this,m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,b0,b1,b2,b3,b4,b5,b6,b7,b8,b9,c0,c1,c2,c3,c4,c5,c6,c7,c8
var $async$$0=A.d(function(c9,d0){if(c9===1){p.push(d0)
s=q}for(;;)switch(s){case 0:c6=n.a
c7=c6.d.a
c7===$&&A.P()
c7=new A.bO(A.bA(new A.a4(c7,A.p(c7).h("a4<1>")),"stream",t.K))
q=2
a6=c6.x,a7=t.D,a8=c6.r
case 5:s=7
return A.b(c7.l(),$async$$0)
case 7:if(!d0){s=6
break}m=c7.gp()
q=9
l=m
k=null
j=!1
i=null
h=!1
g=null
f=null
e=null
d=null
a9=l instanceof A.fY
if(a9){if(j)b0=k
else{j=!0
b1=l.a
k=b1
b0=b1}g=b0
f=l.b
e=l.c
if(h)b2=i
else{h=!0
b3=l.d
i=b3
b2=b3}d=b2}s=a9?13:14
break
case 13:a6.m(0,g,d)
c=null
b=null
a9=c6.b
b4=f
b5=b4.c
if(b5==null){b5=a9.c
if(b5==null)b5=B.G}b6=b4.d
if(b6==null){b6=a9.d
if(b6==null)b6=B.u}b7=b4.b
if(b7==null){b7=a9.b
if(b7==null)b7=B.K}b8=b4.e
b9=b4.f
if(b9==null)b9=a9.f!==!1
c0=b4.a
if(c0==null){c0=a9.a
if(c0==null)c0=B.L}c1=b4.r
if(c1==null)c1=a9.r
c2=b4.w
if(c2==null){c2=a9.w
if(c2==null)c2=B.r}b4=b4.x
c3=a9.b
c4=!0
if(B.x.bG(b7,c3==null?B.K:c3)){c3=a9.c
if(b5.D(0,c3==null?B.G:c3)){c3=a9.d
if(b6.D(0,c3==null?B.u:c3))if(b8===a9.e)if(b9===(a9.f!==!1)){c3=a9.a
if(B.x.bG(c0,c3==null?B.L:c3)){c3=a9.w
a9=!c2.D(0,c3==null?B.r:c3)||b4!==a9.x}else a9=c4}else a9=c4
else a9=c4
else a9=c4
c4=a9}}a=new A.N(new A.fN(c0,b7,b5,b6,b8,b9,c1,c2,b4),c4)
c=a.a
b=a.b
c6.b=c
c6.c=e
a9=c6.f
s=a9==null?15:17
break
case 15:s=18
return A.b(c6.c0(g),$async$$0)
case 18:s=16
break
case 17:s=b?19:21
break
case 19:a9.ar()
c6.f=null
s=22
return A.b(c6.c0(g),$async$$0)
case 22:s=20
break
case 21:c6.jr()
case 20:case 16:a9=g.a
a9===$&&A.P()
a9.y.postMessage({type:"notifySyncStatus",payload:a8})
s=12
break
case 14:a0=null
a9=l instanceof A.hr
if(a9){if(j)b0=k
else{j=!0
b1=l.a
k=b1
b0=b1}a0=b0}s=a9?23:24
break
case 23:a6.H(0,a0)
s=a6.a===0?25:27
break
case 25:a9=c6.f
a9=a9==null?null:a9.ar()
if(!(a9 instanceof A.l)){b4=new A.l($.o,a7)
b4.a=8
b4.c=a9
a9=b4}s=28
return A.b(a9,$async$$0)
case 28:c6.f=null
s=26
break
case 27:s=J.A(a0,c6.w)?29:30
break
case 29:s=31
return A.b(c6.ci(),$async$$0)
case 31:case 30:case 26:s=12
break
case 24:a1=null
a9=l instanceof A.h6
if(a9){if(j)b0=k
else{j=!0
b1=l.a
k=b1
b0=b1}a1=b0}s=a9?32:33
break
case 32:a6.H(0,a1)
a9=c6.f
a9=a9==null?null:a9.ar()
if(!(a9 instanceof A.l)){b4=new A.l($.o,a7)
b4.a=8
b4.c=a9
a9=b4}s=34
return A.b(a9,$async$$0)
case 34:c6.f=null
s=12
break
case 33:a2=null
a3=null
a9=l instanceof A.h3
if(a9){if(j)b0=k
else{j=!0
b1=l.a
k=b1
b0=b1}a2=b0
if(h)b2=i
else{h=!0
b3=l.b
i=b3
b2=b3}a3=b2}if(a9){a6.m(0,a2,a3)
c6.jr()}case 12:q=2
s=11
break
case 9:q=8
c8=p.pop()
a4=A.E(c8)
a5=A.M(c8)
a9=$.cN()
b4=A.q(m)
a9.P(B.i,"Error handling "+b4,a4,a5)
s=11
break
case 8:s=2
break
case 11:s=5
break
case 6:o.push(4)
s=3
break
case 2:o=[1]
case 3:q=1
s=35
return A.b(c7.u(),$async$$0)
case 35:s=o.pop()
break
case 4:return A.f(null,r)
case 1:return A.e(p.at(-1),r)}})
return A.h($async$$0,r)},
$S:40}
A.pd.prototype={
$1(a){var s;--this.a.a
s=this.b
if((s.a.a&30)===0)s.U(this.c)},
$S:9}
A.pe.prototype={
$0(){var s=this,r=s.a;--r.a
s.b.fX()
if(r.a===0&&(s.c.a.a&30)===0)s.c.U(null)},
$S:1}
A.pf.prototype={
$1(a){$.cN().P(B.p,"Detected closed client",null,null)
this.a.fX()},
$S:9}
A.pg.prototype={
$1(a){var s,r,q,p,o,n,m=this
$.cN().P(B.p,"Broadcasting status update: "+a.j(0),null,null)
s={}
r=a.a
if(r!=null){q=B.h.b9(r.a)
m.a.r.core=q
s.core=q}p=a.b
if(p!=null){m.a.r.uploading=p
s.uploading=p}o=a.c
if(o!=null){o=A.x8(o)
m.a.r.downloadError=o
s.downloadError=o}o=a.d
if(o!=null){o=A.x8(o)
m.a.r.uploadError=o
s.uploadError=o}for(o=m.a.x,o=new A.d2(o,o.r,o.e);o.l();){n=o.d.a
n===$&&A.P()
n.y.postMessage({type:"notifySyncStatus",payload:s})}},
$S:80}
A.ph.prototype={
$1(a){var s,r
$.cN().P(B.p,"Broadcasting diagnostic event: "+a,null,null)
for(s=this.a.x,s=new A.d2(s,s.r,s.e);s.l();){r=s.d.a
r===$&&A.P()
r.y.postMessage({type:"handleDiagnostics",payload:a})}},
$S:81}
A.fY.prototype={$ibN:1}
A.hr.prototype={$ibN:1}
A.h6.prototype={$ibN:1}
A.h3.prototype={$ibN:1}
A.ad.prototype={
aE(){return"SyncWorkerMessageType."+this.b}}
A.pI.prototype={
$1(a){var s,r,q,p,o
t.c.a(a)
s=t.k.b(a)?a:new A.ae(a,A.a5(a).h("ae<1,j>"))
r=J.aa(s)
q=r.gk(s)===2
if(q){p=r.i(s,0)
o=r.i(s,1)}else{p=null
o=null}if(!q)throw A.c(A.z("Pattern matching error"))
return new A.ke(p,o)},
$S:82}
A.jE.prototype={
kM(a,b,c,d,e){var s=this,r=s.y
r.start()
s.w=null
s.r=A.aC(r,"message",new A.qk(s),!1,t.m)},
c1(a,b){return this.m9(a,b)},
m9(a,b){var s=0,r=A.i(t.H),q=1,p=[],o=this,n,m,l,k,j,i,h,g,f,e
var $async$c1=A.d(function(c,d){if(c===1){p.push(d)
s=q}for(;;)switch(s){case 0:q=3
n=null
m=null
g=b.$0()
s=6
return A.b(t.nK.b(g)?g:A.bL(g,t.iu),$async$c1)
case 6:l=d
n=l.a
m=l.b
k={type:"okResponse",payload:{requestId:a,payload:n}}
g=o.y
if(m!=null)g.postMessage(k,m)
else g.postMessage(k)
q=1
s=5
break
case 3:q=2
e=p.pop()
j=A.E(e)
i=null
h=j
A:{if(h instanceof A.cv){i=1
break A}if(h instanceof A.bB){i=2
break A}i=0
break A}o.y.postMessage({type:"errorResponse",payload:{requestId:a,recognizedType:i,errorMessage:J.bb(j)}})
s=5
break
case 2:s=1
break
case 5:return A.f(null,r)
case 1:return A.e(p.at(-1),r)}})
return A.h($async$c1,r)},
dN(){var s,r,q=this
if(q.e||(q.c.a.a&30)!==0)throw A.c(A.z("Channel has error, cannot send new requests"))
s=q.d++
r=new A.l($.o,t.ny)
q.a.m(0,s,new A.L(r,t.gW))
return new A.N(s,r)},
dO(a,b){var s=this.dN(),r=s.a
this.y.postMessage({type:a.b,payload:r})
this.hR(r,b)
return s.b},
i3(a){return this.dO(a,null)},
hR(a,b){if(b!=null)b.aK(new A.qj(this,a),t.P)},
eq(){var s=0,r=A.i(t.H),q=this
var $async$eq=A.d(function(a,b){if(a===1)return A.e(b,r)
for(;;)switch(s){case 0:s=2
return A.b(q.i3(B.O),$async$eq)
case 2:return A.f(null,r)}})
return A.h($async$eq,r)},
ev(){var s=0,r=A.i(t.m),q,p=this,o
var $async$ev=A.d(function(a,b){if(a===1)return A.e(b,r)
for(;;)switch(s){case 0:o=A
s=3
return A.b(p.i3(B.Q),$async$ev)
case 3:q=o.Q(b)
s=1
break
case 1:return A.f(q,r)}})
return A.h($async$ev,r)},
cp(a){return this.mT(a)},
mT(a){var s=0,r=A.i(t.J),q,p=this,o,n
var $async$cp=A.d(function(b,c){if(b===1)return A.e(c,r)
for(;;)switch(s){case 0:n=A
s=3
return A.b(p.dO(B.T,a),$async$cp)
case 3:o=n.vP(c)
q=o==null?null:A.x7(o)
s=1
break
case 1:return A.f(q,r)}})
return A.h($async$cp,r)},
c8(a,b){return this.ot(a,b)},
ot(a,b){var s=0,r=A.i(t.J),q,p=this,o,n
var $async$c8=A.d(function(c,d){if(c===1)return A.e(d,r)
for(;;)switch(s){case 0:n=A
s=3
return A.b(p.dO(a?B.S:B.P,b),$async$c8)
case 3:o=n.vP(d)
q=o==null?null:A.x7(o)
s=1
break
case 1:return A.f(q,r)}})
return A.h($async$c8,r)},
ex(a){return this.oP(a)},
oP(a){var s=0,r=A.i(t.H),q=this
var $async$ex=A.d(function(b,c){if(b===1)return A.e(c,r)
for(;;)switch(s){case 0:s=2
return A.b(q.dO(B.R,a),$async$ex)
case 2:return A.f(null,r)}})
return A.h($async$ex,r)},
e9(a,b,c){return this.mU(a,b,c)},
mU(a,b,c){var s=0,r=A.i(t.T),q,p=this,o,n,m,l
var $async$e9=A.d(function(d,e){if(d===1)return A.e(e,r)
for(;;)switch(s){case 0:n=p.dN()
m=n.a
p.y.postMessage({type:"customCheckpointRequest",payload:{req:m,clientId:a,requestId:b}})
p.hR(m,c)
l=A
s=3
return A.b(n.b,$async$e9)
case 3:o=l.kE(e)
q=o==null?null:o
s=1
break
case 1:return A.f(q,r)}})
return A.h($async$e9,r)},
dC(a){return this.kj(a)},
kj(a){var s=0,r=A.i(t.m),q,p=this,o,n
var $async$dC=A.d(function(b,c){if(b===1)return A.e(c,r)
for(;;)switch(s){case 0:o=p.dN()
a.r=o.a
p.y.postMessage({type:"sendHttpRequest",payload:a},[a.b])
n=A
s=3
return A.b(o.b,$async$dC)
case 3:q=n.Q(c)
s=1
break
case 1:return A.f(q,r)}})
return A.h($async$dC,r)},
er(a){return this.ov(a)},
ov(a){var s=0,r=A.i(t.aC),q,p=this,o,n
var $async$er=A.d(function(b,c){if(b===1)return A.e(c,r)
for(;;)switch(s){case 0:o=p.dN()
p.y.postMessage({type:"readResponseChunk",payload:{r:o.a,i:a}})
n=t.aC
s=3
return A.b(o.b,$async$er)
case 3:q=n.a(c)
s=1
break
case 1:return A.f(q,r)}})
return A.h($async$er,r)},
n(){var s=0,r=A.i(t.H),q=this,p,o,n
var $async$n=A.d(function(a,b){if(a===1)return A.e(b,r)
for(;;)switch(s){case 0:n=q.c
if((n.a.a&30)===0){p=q.r
if(p!=null)p.u()
q.y.close()
p=q.at
if(p!=null)p.pK()
for(p=q.a,p=new A.b3(p,p.r,p.e);p.l();)p.d.a9(B.aN)
for(p=q.b,o=new A.b3(p,p.r,p.e);o.l();)o.d.L()
p.aF(0)
n.L()}return A.f(null,r)}})
return A.h($async$n,r)}}
A.qk.prototype={
$1(a){return this.jW(a)},
jW(a0){var s=0,r=A.i(t.H),q,p=2,o=[],n=[],m=this,l,k,j,i,h,g,f,e,d,c,b,a
var $async$$1=A.d(function(a1,a2){if(a1===1){o.push(a2)
s=p}for(;;)A:switch(s){case 0:d=A.Q(a0.data)
c=A.mS(B.bo,d.type)
b=m.a
a=b.as
a.P(B.p,"[in] "+A.q(c),null,null)
l=null
switch(c){case B.O:l=A.O(A.by(d.payload))
q=b.c1(l,new A.qf())
s=1
break A
case B.ap:l=A.Q(d.payload).requestId
break
case B.az:l=A.Q(d.payload).requestId
break
case B.Q:case B.aA:case B.T:case B.S:case B.P:case B.R:case B.aC:l=A.O(A.by(d.payload))
break
case B.aB:l=A.O(A.Q(d.payload).req)
break
case B.au:h=A.Q(d.payload)
q=b.c1(h.r,new A.qg(b,h))
s=1
break A
case B.av:g=A.Q(d.payload)
a=g.i
f=g.r
a=b.at.b.H(0,a)
if(a!=null)a.iC(f)
s=1
break A
case B.aw:h=A.Q(d.payload)
q=b.c1(h.r,new A.qh(b,h))
s=1
break A
case B.ax:g=A.Q(d.payload)
b.a.H(0,g.requestId).U(g.payload)
s=1
break A
case B.ay:g=A.Q(d.payload)
a=g.recognizedType
switch(a==null?0:a){case 1:a=new A.cv("Request aborted by `abortTrigger`",null)
break
case 2:a=new A.bB("aborted over web channel")
break
default:a=g.errorMessage
break}b.a.H(0,g.requestId).a9(a)
s=1
break A
case B.ar:case B.as:b.Q.q(0,new A.N(c,d.payload))
s=1
break A
case B.at:a.P(B.m,"[Sync Worker]: "+A.ak(d.payload),null,null)
s=1
break A
case B.aq:b=b.b.H(0,A.O(A.by(d.payload)))
if(b!=null)b.L()
s=1
break A}a=b.b
f=l
e=new A.a9(new A.l($.o,t.D),t.h)
a.m(0,f,e)
k=e
p=3
s=6
return A.b(b.c1(l,new A.qi(b,c,d,k)),$async$$1)
case 6:n.push(5)
s=4
break
case 3:n=[2]
case 4:p=2
j=a.H(0,l)
i=null
if(j!=null){i=j
i.L()}s=n.pop()
break
case 5:case 1:return A.f(q,r)
case 2:return A.e(o.at(-1),r)}})
return A.h($async$$1,r)},
$S:83}
A.qf.prototype={
$0(){var s=0,r=A.i(t.lg),q
var $async$$0=A.d(function(a,b){if(a===1)return A.e(b,r)
for(;;)switch(s){case 0:q=B.ai
s=1
break
case 1:return A.f(q,r)}})
return A.h($async$$0,r)},
$S:84}
A.qg.prototype={
$0(){var s=0,r=A.i(t.iS),q,p=this,o
var $async$$0=A.d(function(a,b){if(a===1)return A.e(b,r)
for(;;)switch(s){case 0:o=A
s=3
return A.b(p.a.at.pL(p.b),$async$$0)
case 3:q=new o.N(b,null)
s=1
break
case 1:return A.f(q,r)}})
return A.h($async$$0,r)},
$S:85}
A.qh.prototype={
$0(){var s=0,r=A.i(t.jc),q,p=this,o,n
var $async$$0=A.d(function(a,b){if(a===1)return A.e(b,r)
for(;;)switch(s){case 0:s=3
return A.b(p.a.at.pM(p.b.i),$async$$0)
case 3:n=b
A:{if(n==null){o=B.ai
break A}o=new A.N(n,[n])
break A}q=o
s=1
break
case 1:return A.f(q,r)}})
return A.h($async$$0,r)},
$S:86}
A.qi.prototype={
$0(){var s=this
return s.a.z.$3(s.b,s.c.payload,s.d.a)},
$S:87}
A.qj.prototype={
$1(a){var s=this.a,r=this.b
if(s.a.F(r)&&(s.c.a.a&30)===0)s.y.postMessage({type:"abortRequest",payload:r})},
$S:9}
A.oe.prototype={}
A.j2.prototype={
oO(a){return this.a.ex(a)}}
A.i6.prototype={
j(a){return"Worker communication channel closed"},
$iJ:1}
A.uD.prototype={
$1(a){var s=A.Q(a.data)
if(s.isForSyncWorker)A.A_(A.Q(s.message),this.a)
else this.b.q(0,new v.G.MessageEvent("message",{data:s.message}))},
$S:2}
A.uE.prototype={
$1(a){a.start()
A.aC(a,"message",this.a,!1,t.m)},
$S:2}
A.uC.prototype={
$1(a){var s,r=a.ports
r=J.a0(t.ip.b(r)?r:new A.ae(r,A.a5(r).h("ae<1,v>")))
s=this.a
while(r.l())s.$1(r.gp())},
$S:2}
A.rq.prototype={
n(){if($.zk())v.G.close()},
gmQ(){return this.a},
gnZ(){return this.b}}
A.o1.prototype={}
A.o3.prototype={
eL(){return this.a.eL()}}
A.oy.prototype={
gk(a){return this.c.length},
go6(){return this.b.length},
kH(a,b){var s,r,q,p,o,n,m,l,k
for(s=this.c,r=s.length,q=a.a,p=s.$flags|0,o=q.length,n=this.b,m=0;m<r;++m){l=q.charCodeAt(m)
p&2&&A.B(s)
s[m]=l
if(l===13){k=m+1
if(k>=o||q.charCodeAt(k)!==10)l=10}if(l===10)n.push(m+1)}},
cH(a){var s,r=this
if(a<0)throw A.c(A.ay("Offset may not be negative, was "+a+"."))
else if(a>r.c.length)throw A.c(A.ay("Offset "+a+u.D+r.gk(0)+"."))
s=r.b
if(a<B.c.gai(s))return-1
if(a>=B.c.gaP(s))return s.length-1
if(r.lz(a)){s=r.d
s.toString
return s}return r.d=r.kY(a)-1},
lz(a){var s,r,q=this.d
if(q==null)return!1
s=this.b
if(a<s[q])return!1
r=s.length
if(q>=r-1||a<s[q+1])return!0
if(q>=r-2||a<s[q+2]){this.d=q+1
return!0}return!1},
kY(a){var s,r,q=this.b,p=q.length-1
for(s=0;s<p;){r=s+B.b.R(p-s,2)
if(q[r]>a)p=r
else s=r+1}return p},
eJ(a){var s,r,q=this
if(a<0)throw A.c(A.ay("Offset may not be negative, was "+a+"."))
else if(a>q.c.length)throw A.c(A.ay("Offset "+a+" must be not be greater than the number of characters in the file, "+q.gk(0)+"."))
s=q.cH(a)
r=q.b[s]
if(r>a)throw A.c(A.ay("Line "+s+" comes after offset "+a+"."))
return a-r},
dz(a){var s,r,q,p
if(a<0)throw A.c(A.ay("Line may not be negative, was "+a+"."))
else{s=this.b
r=s.length
if(a>=r)throw A.c(A.ay("Line "+a+" must be less than the number of lines in the file, "+this.go6()+"."))}q=s[a]
if(q<=this.c.length){p=a+1
s=p<r&&q>=s[p]}else s=!0
if(s)throw A.c(A.ay("Line "+a+" doesn't have 0 columns."))
return q}}
A.iq.prototype={
gM(){return this.a.a},
gX(){return this.a.cH(this.b)},
ga8(){return this.a.eJ(this.b)},
gaa(){return this.b}}
A.ew.prototype={
gM(){return this.a.a},
gk(a){return this.c-this.b},
gG(){return A.v8(this.a,this.b)},
gC(){return A.v8(this.a,this.c)},
gah(){return A.bI(B.M.bQ(this.a.c,this.b,this.c),0,null)},
gaH(){var s=this,r=s.a,q=s.c,p=r.cH(q)
if(r.eJ(q)===0&&p!==0){if(q-s.b===0)return p===r.b.length-1?"":A.bI(B.M.bQ(r.c,r.dz(p),r.dz(p+1)),0,null)}else q=p===r.b.length-1?r.c.length:r.dz(p+1)
return A.bI(B.M.bQ(r.c,r.dz(r.cH(s.b)),q),0,null)},
a0(a,b){var s
if(!(b instanceof A.ew))return this.kv(0,b)
s=B.b.a0(this.b,b.b)
return s===0?B.b.a0(this.c,b.c):s},
D(a,b){var s=this
if(b==null)return!1
if(!(b instanceof A.ew))return s.ku(0,b)
return s.b===b.b&&s.c===b.c&&J.A(s.a.a,b.a.a)},
gv(a){return A.c_(this.b,this.c,this.a.a,B.d,B.d,B.d)},
$ic1:1}
A.n8.prototype={
nX(){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a=this,a0=null,a1=a.a
a.iz(B.c.gai(a1).c)
s=a.e
r=A.b4(s,a0,!1,t.dd)
for(q=a.r,s=s!==0,p=a.b,o=0;o<a1.length;++o){n=a1[o]
if(o>0){m=a1[o-1]
l=n.c
if(!J.A(m.c,l)){a.dY("\u2575")
q.a+="\n"
a.iz(l)}else if(m.b+1!==n.b){a.mz("...")
q.a+="\n"}}for(l=n.d,k=A.a5(l).h("da<1>"),j=new A.da(l,k),j=new A.as(j,j.gk(0),k.h("as<X.E>")),k=k.h("X.E"),i=n.b,h=n.a;j.l();){g=j.d
if(g==null)g=k.a(g)
f=g.a
if(f.gG().gX()!==f.gC().gX()&&f.gG().gX()===i&&a.lA(B.a.t(h,0,f.gG().ga8()))){e=B.c.c7(r,a0)
if(e<0)A.r(A.H(A.q(r)+" contains no null elements.",a0))
r[e]=g}}a.my(i)
q.a+=" "
a.mx(n,r)
if(s)q.a+=" "
d=B.c.o_(l,new A.nt())
c=d===-1?a0:l[d]
k=c!=null
if(k){j=c.a
g=j.gG().gX()===i?j.gG().ga8():0
a.mv(h,g,j.gC().gX()===i?j.gC().ga8():h.length,p)}else a.e_(h)
q.a+="\n"
if(k)a.mw(n,c,r)
for(l=l.length,b=0;b<l;++b)continue}a.dY("\u2575")
a1=q.a
return a1.charCodeAt(0)==0?a1:a1},
iz(a){var s,r,q=this
if(!q.f||!t.R.b(a))q.dY("\u2577")
else{q.dY("\u250c")
q.aM(new A.ng(q),"\x1b[34m")
s=q.r
r=" "+$.wf().jn(a)
s.a+=r}q.r.a+="\n"},
dW(a,b,c){var s,r,q,p,o,n,m,l,k,j,i,h=this,g={}
g.a=!1
g.b=null
s=c==null
if(s)r=null
else r=h.b
for(q=b.length,p=h.b,s=!s,o=h.r,n=!1,m=0;m<q;++m){l=b[m]
k=l==null
j=k?null:l.a.gG().gX()
i=k?null:l.a.gC().gX()
if(s&&l===c){h.aM(new A.nn(h,j,a),r)
n=!0}else if(n)h.aM(new A.no(h,l),r)
else if(k)if(g.a)h.aM(new A.np(h),g.b)
else o.a+=" "
else h.aM(new A.nq(g,h,c,j,a,l,i),p)}},
mx(a,b){return this.dW(a,b,null)},
mv(a,b,c,d){var s=this
s.e_(B.a.t(a,0,b))
s.aM(new A.nh(s,a,b,c),d)
s.e_(B.a.t(a,c,a.length))},
mw(a,b,c){var s,r=this,q=r.b,p=b.a
if(p.gG().gX()===p.gC().gX()){r.fw()
p=r.r
p.a+=" "
r.dW(a,c,b)
if(c.length!==0)p.a+=" "
r.iA(b,c,r.aM(new A.ni(r,a,b),q))}else{s=a.b
if(p.gG().gX()===s){if(B.c.V(c,b))return
A.El(c,b)
r.fw()
p=r.r
p.a+=" "
r.dW(a,c,b)
r.aM(new A.nj(r,a,b),q)
p.a+="\n"}else if(p.gC().gX()===s){p=p.gC().ga8()
if(p===a.a.length){A.yP(c,b)
return}r.fw()
r.r.a+=" "
r.dW(a,c,b)
r.iA(b,c,r.aM(new A.nk(r,!1,a,b),q))
A.yP(c,b)}}},
iy(a,b,c){var s=c?0:1,r=this.r
s=B.a.aL("\u2500",1+b+this.f1(B.a.t(a.a,0,b+s))*3)
r.a=(r.a+=s)+"^"},
mu(a,b){return this.iy(a,b,!0)},
iA(a,b,c){this.r.a+="\n"
return},
e_(a){var s,r,q,p
for(s=new A.bn(a),r=t.V,s=new A.as(s,s.gk(0),r.h("as<y.E>")),q=this.r,r=r.h("y.E");s.l();){p=s.d
if(p==null)p=r.a(p)
if(p===9)q.a+=B.a.aL(" ",4)
else{p=A.aQ(p)
q.a+=p}}},
dZ(a,b,c){var s={}
s.a=c
if(b!=null)s.a=B.b.j(b+1)
this.aM(new A.nr(s,this,a),"\x1b[34m")},
dY(a){return this.dZ(a,null,null)},
mz(a){return this.dZ(null,null,a)},
my(a){return this.dZ(null,a,null)},
fw(){return this.dZ(null,null,null)},
f1(a){var s,r,q,p
for(s=new A.bn(a),r=t.V,s=new A.as(s,s.gk(0),r.h("as<y.E>")),r=r.h("y.E"),q=0;s.l();){p=s.d
if((p==null?r.a(p):p)===9)++q}return q},
lA(a){var s,r,q
for(s=new A.bn(a),r=t.V,s=new A.as(s,s.gk(0),r.h("as<y.E>")),r=r.h("y.E");s.l();){q=s.d
if(q==null)q=r.a(q)
if(q!==32&&q!==9)return!1}return!0},
l3(a,b){var s,r=this.b!=null
if(r&&b!=null)this.r.a+=b
s=a.$0()
if(r&&b!=null)this.r.a+="\x1b[0m"
return s},
aM(a,b){return this.l3(a,b,t.z)}}
A.ns.prototype={
$0(){return this.a},
$S:89}
A.na.prototype={
$1(a){var s=a.d
return new A.c7(s,new A.n9(),A.a5(s).h("c7<1>")).gk(0)},
$S:90}
A.n9.prototype={
$1(a){var s=a.a
return s.gG().gX()!==s.gC().gX()},
$S:29}
A.nb.prototype={
$1(a){return a.c},
$S:92}
A.nd.prototype={
$1(a){var s=a.a.gM()
return s==null?new A.k():s},
$S:93}
A.ne.prototype={
$2(a,b){return a.a.a0(0,b.a)},
$S:94}
A.nf.prototype={
$1(a){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d=a.a,c=a.b,b=A.u([],t.dg)
for(s=J.bk(c),r=s.gA(c),q=t.g7;r.l();){p=r.gp().a
o=p.gaH()
n=A.uq(o,p.gah(),p.gG().ga8())
n.toString
m=B.a.e2("\n",B.a.t(o,0,n)).gk(0)
l=p.gG().gX()-m
for(p=o.split("\n"),n=p.length,k=0;k<n;++k){j=p[k]
if(b.length===0||l>B.c.gaP(b).b)b.push(new A.bw(j,l,d,A.u([],q)));++l}}i=A.u([],q)
for(r=b.length,h=i.$flags|0,g=0,k=0;k<b.length;b.length===r||(0,A.a6)(b),++k){j=b[k]
h&1&&A.B(i,16)
B.c.m2(i,new A.nc(j),!0)
f=i.length
for(q=s.aT(c,g),p=q.$ti,q=new A.as(q,q.gk(0),p.h("as<X.E>")),n=j.b,p=p.h("X.E");q.l();){e=q.d
if(e==null)e=p.a(e)
if(e.a.gG().gX()>n)break
i.push(e)}g+=i.length-f
B.c.a7(j.d,i)}return b},
$S:95}
A.nc.prototype={
$1(a){return a.a.gC().gX()<this.a.b},
$S:29}
A.nt.prototype={
$1(a){return!0},
$S:29}
A.ng.prototype={
$0(){this.a.r.a+=B.a.aL("\u2500",2)+">"
return null},
$S:0}
A.nn.prototype={
$0(){var s=this.a.r,r=this.b===this.c.b?"\u250c":"\u2514"
s.a+=r},
$S:1}
A.no.prototype={
$0(){var s=this.a.r,r=this.b==null?"\u2500":"\u253c"
s.a+=r},
$S:1}
A.np.prototype={
$0(){this.a.r.a+="\u2500"
return null},
$S:0}
A.nq.prototype={
$0(){var s,r,q=this,p=q.a,o=p.a?"\u253c":"\u2502"
if(q.c!=null)q.b.r.a+=o
else{s=q.e
r=s.b
if(q.d===r){s=q.b
s.aM(new A.nl(p,s),p.b)
p.a=!0
if(p.b==null)p.b=s.b}else{s=q.r===r&&q.f.a.gC().ga8()===s.a.length
r=q.b
if(s)r.r.a+="\u2514"
else r.aM(new A.nm(r,o),p.b)}}},
$S:1}
A.nl.prototype={
$0(){var s=this.b.r,r=this.a.a?"\u252c":"\u250c"
s.a+=r},
$S:1}
A.nm.prototype={
$0(){this.a.r.a+=this.b},
$S:1}
A.nh.prototype={
$0(){var s=this
return s.a.e_(B.a.t(s.b,s.c,s.d))},
$S:0}
A.ni.prototype={
$0(){var s,r,q=this.a,p=q.r,o=p.a,n=this.c.a,m=n.gG().ga8(),l=n.gC().ga8()
n=this.b.a
s=q.f1(B.a.t(n,0,m))
r=q.f1(B.a.t(n,m,l))
m+=s*3
n=(p.a+=B.a.aL(" ",m))+B.a.aL("^",Math.max(l+(s+r)*3-m,1))
p.a=n
return n.length-o.length},
$S:4}
A.nj.prototype={
$0(){return this.a.mu(this.b,this.c.a.gG().ga8())},
$S:0}
A.nk.prototype={
$0(){var s=this,r=s.a,q=r.r,p=q.a
if(s.b)q.a=p+B.a.aL("\u2500",3)
else r.iy(s.c,Math.max(s.d.a.gC().ga8()-1,0),!1)
return q.a.length-p.length},
$S:4}
A.nr.prototype={
$0(){var s=this.b,r=s.r,q=this.a.a
if(q==null)q=""
s=B.a.or(q,s.d)
s=r.a+=s
q=this.c
r.a=s+(q==null?"\u2502":q)},
$S:1}
A.aP.prototype={
j(a){var s=this.a
s="primary "+(""+s.gG().gX()+":"+s.gG().ga8()+"-"+s.gC().gX()+":"+s.gC().ga8())
return s.charCodeAt(0)==0?s:s}}
A.rP.prototype={
$0(){var s,r,q,p,o=this.a
if(!(t.ol.b(o)&&A.uq(o.gaH(),o.gah(),o.gG().ga8())!=null)){s=A.j9(o.gG().gaa(),0,0,o.gM())
r=o.gC().gaa()
q=o.gM()
p=A.DN(o.gah(),10)
o=A.oz(s,A.j9(r,A.xE(o.gah()),p,q),o.gah(),o.gah())}return A.BM(A.BO(A.BN(o)))},
$S:97}
A.bw.prototype={
j(a){return""+this.b+': "'+this.a+'" ('+B.c.bp(this.d,", ")+")"}}
A.bt.prototype={
fG(a){var s=this.a
if(!J.A(s,a.gM()))throw A.c(A.H('Source URLs "'+A.q(s)+'" and "'+A.q(a.gM())+"\" don't match.",null))
return Math.abs(this.b-a.gaa())},
a0(a,b){var s=this.a
if(!J.A(s,b.gM()))throw A.c(A.H('Source URLs "'+A.q(s)+'" and "'+A.q(b.gM())+"\" don't match.",null))
return this.b-b.gaa()},
D(a,b){if(b==null)return!1
return t.hq.b(b)&&J.A(this.a,b.gM())&&this.b===b.gaa()},
gv(a){var s=this.a
s=s==null?null:s.gv(s)
if(s==null)s=0
return s+this.b},
j(a){var s=this,r=A.uv(s).j(0),q=s.a
return"<"+r+": "+s.b+" "+(A.q(q==null?"unknown source":q)+":"+(s.c+1)+":"+(s.d+1))+">"},
$ia7:1,
gM(){return this.a},
gaa(){return this.b},
gX(){return this.c},
ga8(){return this.d}}
A.ja.prototype={
fG(a){if(!J.A(this.a.a,a.gM()))throw A.c(A.H('Source URLs "'+A.q(this.gM())+'" and "'+A.q(a.gM())+"\" don't match.",null))
return Math.abs(this.b-a.gaa())},
a0(a,b){if(!J.A(this.a.a,b.gM()))throw A.c(A.H('Source URLs "'+A.q(this.gM())+'" and "'+A.q(b.gM())+"\" don't match.",null))
return this.b-b.gaa()},
D(a,b){if(b==null)return!1
return t.hq.b(b)&&J.A(this.a.a,b.gM())&&this.b===b.gaa()},
gv(a){var s=this.a.a
s=s==null?null:s.gv(s)
if(s==null)s=0
return s+this.b},
j(a){var s=A.uv(this).j(0),r=this.b,q=this.a,p=q.a
return"<"+s+": "+r+" "+(A.q(p==null?"unknown source":p)+":"+(q.cH(r)+1)+":"+(q.eJ(r)+1))+">"},
$ia7:1,
$ibt:1}
A.jc.prototype={
kI(a,b,c){var s,r=this.b,q=this.a
if(!J.A(r.gM(),q.gM()))throw A.c(A.H('Source URLs "'+A.q(q.gM())+'" and  "'+A.q(r.gM())+"\" don't match.",null))
else if(r.gaa()<q.gaa())throw A.c(A.H("End "+r.j(0)+" must come after start "+q.j(0)+".",null))
else{s=this.c
if(s.length!==q.fG(r))throw A.c(A.H('Text "'+s+'" must be '+q.fG(r)+" characters long.",null))}},
gG(){return this.a},
gC(){return this.b},
gah(){return this.c}}
A.jd.prototype={
gjh(){return this.a},
j(a){var s,r,q,p=this.b,o="line "+(p.gG().gX()+1)+", column "+(p.gG().ga8()+1)
if(p.gM()!=null){s=p.gM()
r=$.wf()
s.toString
s=o+(" of "+r.jn(s))
o=s}o+=": "+this.a
q=p.nY(null)
p=q.length!==0?o+"\n"+q:o
return"Error on "+(p.charCodeAt(0)==0?p:p)},
$iJ:1}
A.e8.prototype={
gaa(){var s=this.b
s=A.v8(s.a,s.b)
return s.b},
$iaT:1,
gdD(){return this.c}}
A.e9.prototype={
gM(){return this.gG().gM()},
gk(a){return this.gC().gaa()-this.gG().gaa()},
a0(a,b){var s=this.gG().a0(0,b.gG())
return s===0?this.gC().a0(0,b.gC()):s},
nY(a){var s=this
if(!t.ol.b(s)&&s.gk(s)===0)return""
return A.Ag(s,a).nX()},
D(a,b){if(b==null)return!1
return b instanceof A.e9&&this.gG().D(0,b.gG())&&this.gC().D(0,b.gC())},
gv(a){return A.c_(this.gG(),this.gC(),B.d,B.d,B.d,B.d)},
j(a){var s=this
return"<"+A.uv(s).j(0)+": from "+s.gG().j(0)+" to "+s.gC().j(0)+' "'+s.gah()+'">'},
$ia7:1}
A.c1.prototype={
gaH(){return this.d}}
A.eb.prototype={
aE(){return"SqliteUpdateKind."+this.b}}
A.b7.prototype={
gv(a){return A.c_(this.a,this.b,this.c,B.d,B.d,B.d)},
D(a,b){if(b==null)return!1
return b instanceof A.b7&&b.a===this.a&&b.b===this.b&&b.c===this.c},
j(a){return"SqliteUpdate: "+this.a.j(0)+" on "+this.b+", rowid = "+this.c}}
A.cx.prototype={}
A.jj.prototype={
j(a){var s=this.a
return"SqliteTraceStatement: "+(s==null?"<no sql>":s)+" ("+this.b+")"}}
A.ea.prototype={
j(a){return"SqliteTraceProfile: "+this.a.j(0)+" ("+this.b+")"}}
A.ji.prototype={
j(a){return"SqliteTraceRow ("+this.a+")"}}
A.dc.prototype={
j(a){var s,r,q=this,p=q.e
p=p==null?"":"while "+p+", "
p="SqliteException("+q.c+"): "+p+q.a
s=q.b
if(s!=null)p=p+", "+s
s=q.f
if(s!=null){r=q.d
r=r!=null?" (at position "+A.q(r)+"): ":": "
s=p+"\n  Causing statement"+r+s
p=q.r
p=p!=null?s+(", parameters: "+J.dI(p,new A.oE(),t.N).bp(0,", ")):s}return p.charCodeAt(0)==0?p:p},
$iJ:1}
A.oE.prototype={
$1(a){if(t.p.b(a))return"blob ("+a.length+" bytes)"
else return J.bb(a)},
$S:43}
A.mw.prototype={
ix(){var s=this,r=s.d
return r==null?s.d=new A.cF(s,A.u([],t.fU),new A.mF(s),new A.mG(s),t.jy):r},
mb(){var s=this,r=s.e
return r==null?s.e=new A.cF(s,A.u([],t.lw),new A.mC(s),new A.mD(s),t.lU):r},
f_(){var s=this,r=s.f
return r==null?s.f=new A.cF(s,A.u([],t.lw),new A.my(s),new A.mz(s),t.af):r},
n(){var s,r,q,p=this
if(p.w)return
p.w=!0
s=p.d
if(s!=null)s.n()
s=p.f
if(s!=null)s.n()
s=p.e
if(s!=null)s.n()
s=p.b
r=s.hj()
q=r!==0?A.w1(p.a,s,r,"closing database",null,null):null
if(q!=null)throw A.c(q)},
aY(a,b){var s,r,q
if(this.w)A.r(A.z("This database has already been closed"))
s=this.b
r=s.a
q=r.d3(B.o.av(a),1)
r=r.d
s=A.yz(r,"sqlite3_exec",[s.b,q,0,0,0])
r.dart_sqlite3_free(q)
if(s!==0)A.w8(this,s,"executing",a,b)},
gd4(){if(this.w)A.r(A.z("This database has already been closed"))
var s=this.b
return s.a.d.sqlite3_get_autocommit(s.b)!==0},
lV(a,b,c,d,a0){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e=this
if(e.w)A.r(A.z("This database has already been closed"))
s=B.o.av(a)
r=e.b
q=r.a
p=q.fB(s)
o=q.ek(4)
n=q.ek(4)
m=new A.q_(r,p,o,n)
l=A.u([],t.lE)
k=new A.mA(m,l)
for(r=s.length,q=q.b,j=0;j<r;j=g){i=m.hk(j,r-j,0)
o=i.b
if(o!==0){k.$0()
A.w8(e,o,"preparing statement",a,null)}o=q.buffer
h=B.b.R(o.byteLength,4)
g=new Int32Array(o,0,h)[B.b.Z(n,2)]-p
f=i.a
if(f!=null)l.push(new A.ed(f,e,new A.cI(!1).cQ(s,j,g,!0)))
if(l.length===c){j=g
break}}if(b)while(j<r){i=m.hk(j,r-j,0)
o=q.buffer
h=B.b.R(o.byteLength,4)
j=new Int32Array(o,0,h)[B.b.Z(n,2)]-p
f=i.a
if(f!=null){l.push(new A.ed(f,e,""))
k.$0()
throw A.c(A.aZ(a,"sql","Had an unexpected trailing statement."))}else if(i.b!==0){k.$0()
throw A.c(A.aZ(a,"sql","Has trailing data after the first sql statement:"))}}m.n()
return l},
jm(a,b){var s=this.lV(a,b,1,!1,!0)
if(s.length===0)throw A.c(A.aZ(a,"sql","Must contain an SQL statement."))
return B.c.gai(s)},
ou(a){return this.jm(a,!1)}}
A.mF.prototype={
$0(){var s=this.a,r=s.b
r.a.iU(r.b,new A.mE(s))},
$S:0}
A.mE.prototype={
$3(a,b,c){var s=A.B3(a)
if(s==null)return
this.a.d.fF(new A.b7(s,b,c))},
$S:99}
A.mG.prototype={
$0(){var s=this.a.b
s.a.iU(s.b,null)
return null},
$S:0}
A.mC.prototype={
$0(){var s=this.a,r=s.b
r.a.iT(r.b,new A.mB(s))
return null},
$S:0}
A.mB.prototype={
$0(){this.a.e.fF(null)},
$S:0}
A.mD.prototype={
$0(){var s=this.a.b
s.a.iT(s.b,null)
return null},
$S:0}
A.my.prototype={
$0(){var s=this.a,r=s.b
r.a.iS(r.b,new A.mx(s))
return null},
$S:0}
A.mx.prototype={
$0(){var s=this.a.f
s.fF(null)
return 0},
$S:4}
A.mz.prototype={
$0(){var s=this.a.b
s.a.iS(s.b,null)
return null},
$S:0}
A.mA.prototype={
$0(){var s,r,q,p,o,n
this.a.n()
for(s=this.b,r=s.length,q=0;q<s.length;s.length===r||(0,A.a6)(s),++q){p=s[q]
if(!p.r){p.r=!0
if(!p.f){o=p.a
o.c.d.sqlite3_reset(o.b)
p.f=!0}o=p.a
n=o.c
n.d.sqlite3_finalize(o.b)
n=n.w
if(n!=null){n=n.a
if(n!=null)n.unregister(o.d)}}}},
$S:0}
A.cF.prototype={
gbA(){var s=this.r
return s==null?this.r=this.hS(!1):s},
hS(a){return new A.bx(!0,new A.to(this,a),this.$ti.h("bx<1>"))},
fF(a){var s,r,q,p,o,n,m
for(s=this.c,r=s.length,q=0;q<s.length;s.length===r||(0,A.a6)(s),++q){p=s[q]
o=p.a
if(p.b){n=o.b
if(n>=4)A.r(o.aq())
if((n&1)!==0)o.ga6().N(a)}else{n=o.b
if(n>=4)A.r(o.aq())
if((n&1)!==0)o.a2(a)
else if((n&3)===0){o=o.bV()
n=new A.bv(a)
m=o.c
if(m==null)o.b=o.c=n
else{m.sbs(n)
o.c=n}}}}},
n(){var s,r,q,p=this
for(s=p.c,r=s.length,q=0;q<s.length;s.length===r||(0,A.a6)(s),++q)s[q].a.n()
p.d=null
if(p.b){p.f.$0()
p.b=!1}}}
A.to.prototype={
$1(a){var s,r,q=this.a
if(q.a.w){a.n()
return}s=this.b
r=new A.tp(q,a,s)
a.r=a.e=new A.tq(q,a,s)
a.f=r
r.$0()},
$S(){return this.a.$ti.h("~(bZ<1>)")}}
A.tp.prototype={
$0(){var s=this.a,r=s.c,q=r.length
r.push(new A.hp(this.b,this.c))
if(q===0){if(s.a.w)A.r(A.z("This database has already been closed"))
s.e.$0()
s.b=!0}},
$S:0}
A.tq.prototype={
$0(){var s=this.a,r=s.c
B.c.H(r,new A.hp(this.b,this.c))
r=r.length
if(r===0&&!s.a.w){s.f.$0()
s.b=!1}},
$S:0}
A.oA.prototype={
ja(){var s=null,r=this.a.a.d.sqlite3_initialize()
if(r!==0)throw A.c(A.jh(s,s,r,"Error returned by sqlite3_initialize",s,s,s))},
on(a,b){var s,r,q,p,o,n,m,l,k,j,i
this.ja()
switch(2){case 2:break}s=this.a
r=s.a
q=r.d3(B.o.av(a),1)
p=r.ek(4)
o=r.d3(B.o.av(b),1)
n=r.d
m=n.sqlite3_open_v2(q,p,6,o)
l=A.bq(r.b.buffer,0,null)[B.b.Z(p,2)]
n.dart_sqlite3_free(q)
n.dart_sqlite3_free(p)
n.dart_sqlite3_free(o)
k=new A.k()
j=new A.pT(r,l,k)
r=r.r
if(r!=null)r.iG(j,l,k)
if(m!==0){i=A.w1(s,j,m,"opening the database",null,null)
j.hj()
throw A.c(i)}n.sqlite3_extended_result_codes(l,1)
return new A.mw(s,j,!1)}}
A.ed.prototype={
bv(a,b){A.w8(this.b,a,b,this.d,this.e)},
dL(){if(this.r||this.b.w)throw A.c(A.z(u.f))},
hM(){var s,r=this,q=r.f=!1,p=r.a,o=p.b
p=p.c.d
do s=p.sqlite3_step(o)
while(s===100)
r.dq()
if(s!==0?s!==101:q)r.bv(s,"executing statement")},
kZ(a){var s
this.dL()
s=this.a
s=s.c.d.sqlite3_bind_parameter_count(s.b)
if(0!==s)A.r(A.aZ(a,"parameters","Expected "+A.q(s)+" parameters, got 0"))
return},
hv(a){A:{if(a instanceof A.nx){this.kZ(a.a)
break A}if(a instanceof A.f9)a.a.$1(this)}},
dq(){if(!this.f){var s=this.a
s.c.d.sqlite3_reset(s.b)
this.f=!0}},
n(){var s,r,q=this
if(!q.r){q.r=!0
q.dq()
s=q.a
r=s.c
r.d.sqlite3_finalize(s.b)
r=r.w
if(r!=null)r.iW(s.d)}},
nw(a){var s=this
s.dL()
s.dq()
s.hv(a)
s.hM()}}
A.is.prototype={
eD(a,b){return this.d.F(a)?1:0},
hc(a,b){this.d.H(0,a)},
hd(a){return new v.G.URL(a,"file:///").pathname},
cd(a,b){var s,r=a.a
if(r==null)r=A.wF(this.b,"/")
s=this.d
if(!s.F(r))if((b&4)!==0)s.m(0,r,new A.bd(new Uint8Array(0),0))
else throw A.c(A.c6(14))
return new A.eE(new A.k0(this,r,(b&8)!==0),0)},
hf(a){}}
A.k0.prototype={
jo(a,b){var s,r=this.a.d.i(0,this.b)
if(r==null||r.b<=b)return 0
s=Math.min(a.length,r.b-b)
B.e.af(a,0,s,J.cO(B.e.gau(r.a),b,s))
return s},
hb(){return this.d>=2?1:0},
eE(){if(this.c)this.a.d.H(0,this.b)},
cF(){return this.a.d.i(0,this.b).b},
he(a){this.d=a},
hg(a){},
dv(a){var s=this.a.d,r=this.b,q=s.i(0,r)
if(q==null){s.m(0,r,new A.bd(new Uint8Array(0),0))
s.i(0,r).sk(0,a)}else q.sk(0,a)},
hh(a){this.d=a},
cG(a,b){var s,r=this.a.d,q=this.b,p=r.i(0,q)
if(p==null){p=new A.bd(new Uint8Array(0),0)
r.m(0,q,p)}s=b+a.length
if(s>p.b)p.sk(0,s)
p.af(0,b,s,a)}}
A.uO.prototype={
$1(a){return a.length!==0},
$S:27}
A.m3.prototype={
l_(){var s,r,q,p,o=A.T(t.N,t.S)
for(s=this.a,r=s.length,q=0;q<s.length;s.length===r||(0,A.a6)(s),++q){p=s[q]
o.m(0,p,B.c.cw(s,p))}this.c=o}}
A.bF.prototype={
gA(a){return new A.kl(this)},
i(a,b){return new A.aV(this,A.nM(this.d[b],t.X))},
m(a,b,c){throw A.c(A.R("Can't change rows from a result set"))},
gk(a){return this.d.length},
$ix:1,
$im:1,
$it:1}
A.aV.prototype={
i(a,b){var s
if(typeof b!="string"){if(A.hG(b))return this.b[b]
return null}s=this.a.c.i(0,b)
if(s==null)return null
return this.b[s]},
ga3(){return this.a.a},
$ia3:1}
A.kl.prototype={
gp(){var s=this.a
return new A.aV(s,A.nM(s.d[this.b],t.X))},
l(){return++this.b<this.a.d.length}}
A.km.prototype={}
A.kn.prototype={}
A.ko.prototype={}
A.kp.prototype={}
A.nZ.prototype={
aE(){return"OpenMode."+this.b}}
A.cV.prototype={}
A.nx.prototype={}
A.f9.prototype={}
A.c5.prototype={
j(a){return"VfsException("+this.a+")"},
$iJ:1}
A.fH.prototype={}
A.aB.prototype={}
A.i0.prototype={}
A.i_.prototype={
geF(){return 0},
jD(a,b){return 12},
geH(){return 4096},
eG(a,b){var s=this.jo(a,b),r=a.length
if(s<r){B.e.fJ(a,s,r,0)
throw A.c(B.bW)}},
$iaO:1,
$ifW:1}
A.dl.prototype={}
A.uW.prototype={
$0(){var s,r,q
for(s=this.a;!s.gE(0);){if(s.b===0)A.r(A.z("No such element"))
r=s.c
q=r.a
q.toString
q.ft(A.p(r).h("aG.E").a(r))
r.d.$0()}},
$S:0}
A.uU.prototype={
$1(a){var s=this.a,r=s.b
s.dM(s.c,new A.dl(a),!1)
if(r===0)v.G.Promise.resolve().then(this.b)},
$S:13}
A.uV.prototype={
$4(a,b,c,d){this.a.$1(c.e4(d))},
$S:101}
A.pY.prototype={}
A.pT.prototype={
hj(){var s=this.a,r=s.r
if(r!=null)r.iW(this.c)
return s.d.sqlite3_close_v2(this.b)}}
A.q_.prototype={
n(){var s=this,r=s.a.a.d
r.dart_sqlite3_free(s.b)
r.dart_sqlite3_free(s.c)
r.dart_sqlite3_free(s.d)},
hk(a,b,c){var s,r,q=this,p=q.a,o=p.a,n=q.c
p=A.yz(o.d,"sqlite3_prepare_v3",[p.b,q.b+a,b,c,n,q.d])
s=A.bq(o.b.buffer,0,null)[B.b.Z(n,2)]
if(s===0)r=null
else{n=new A.k()
r=new A.pZ(s,o,n)
o=o.w
if(o!=null)o.iG(r,s,n)}return new A.kf(r,p)}}
A.pZ.prototype={
km(a,b,c,d){var s,r
if(d===0)return
s=this.c
r=s.d.sqlite3_column_blob(this.b,a)
B.e.af(b,c,c+d,A.aU(s.b.buffer,r,d))}}
A.dj.prototype={}
A.cA.prototype={}
A.ei.prototype={
sk(a,b){throw A.c(A.R("Setting length in WasmValueList"))},
i(a,b){A.bq(this.a.b.buffer,0,null)
B.b.Z(this.c+b*4,2)
return new A.cA()},
m(a,b,c){throw A.c(A.R("Setting element in WasmValueList"))},
gk(a){return this.b}}
A.ib.prototype={
og(a){var s=this.b
s===$&&A.P()
A.uR("[sqlite3] "+A.el(s,a,null))},
ob(a,b){var s,r,q,p=A.O(v.G.Number(a))*1000
if(p<-864e13||p>864e13)A.r(A.ab(p,-864e13,864e13,"millisecondsSinceEpoch",null))
s=new A.bS(p,0,!1)
r=this.b
r===$&&A.P()
q=A.AE(r.buffer,b,8)
q.$flags&2&&A.B(q)
q[0]=A.x1(s)
q[1]=A.x_(s)
q[2]=A.wZ(s)
q[3]=A.wY(s)
q[4]=A.x0(s)-1
q[5]=A.x2(s)-1900
q[6]=B.b.aS(A.AL(s),7)},
pm(a,b,c,d,e){var s,r,q,p,o,n,m,l,k,j=null
try{p=this.b
p===$&&A.P()
s=new A.fH(A.qp(p,b,j))
r=a.cd(s,d)
if(e!==0){o=r.b
n=A.bq(p.buffer,0,j)
m=B.b.Z(e,2)
n.$flags&2&&A.B(n)
n[m]=o}p=A.bq(p.buffer,0,j)
o=B.b.Z(c,2)
p.$flags&2&&A.B(p)
p[o]=0
l=r.a
return l}catch(k){p=A.E(k)
if(p instanceof A.c5){q=p
p=this.b
p===$&&A.P()
o=q.a
p=A.bq(p.buffer,0,j)
n=B.b.Z(c,2)
p.$flags&2&&A.B(p)
p[n]=o}else{p=this.b
p===$&&A.P()
p=p.buffer
p=A.bq(p,0,j)
o=B.b.Z(c,2)
p.$flags&2&&A.B(p)
p[o]=1}}return j},
p9(a,b,c){return A.aS(new A.mf(this,b,a,c))},
oY(a,b,c,d){return A.aS(new A.mb(this,b,a,c,d))},
pi(a,b,c,d){return A.aS(new A.mk(this,b,a,c,d))},
po(a,b,c){return A.aS(new A.mm(this,c,b,a))},
pt(a,b){return A.aS(new A.mp(a,b))},
p7(a,b){return A.aS(new A.me(this,a,b))},
p5(a){return A.aS(new A.md(a))},
pq(a,b,c,d){return A.aS(new A.mn(this,a,b,c,d))},
pB(a,b,c,d){return A.aS(new A.mt(this,a,b,c,d))},
px(a,b){return A.aS(new A.mr(a,b))},
pv(a,b){return A.aS(new A.mq(a,b))},
pe(a,b){return A.aS(new A.mj(this,a,b))},
pg(a,b){return A.aS(new A.mi(this,a,b))},
pk(a,b){return A.aS(new A.ml(a,b))},
pz(a,b){return A.aS(new A.ms(a,b))},
p_(a,b){return A.aS(new A.mc(this,a,b))},
pa(a){return A.cg(new A.mg(a),0)},
pc(a,b,c){return A.cg(new A.mh(a,b,c),10)},
pr(a){return A.cg(new A.mo(a),4096)},
nb(a){A.cg(a,null)},
n4(a){return A.cg(a,1)},
n9(a,b,c,d,e){A.cg(new A.m9(this,d,a,b,e),null)},
n7(a,b,c,d){var s,r,q
switch(b){case 1:r=this.b
r===$&&A.P()
r=new A.jj(A.qp(r,d,null),c)
break
case 2:r=new A.m8(this,d,c).$0()
break
case 4:r=new A.ji(c)
break
default:r=null
break}s=r
if(s==null)return 0
try{r=a.$1(s)
return r}catch(q){return 0}},
nh(a,b,c,d){var s=a.gpO(),r=this.a
r===$&&A.P()
s.$2(new A.dj(),new A.ei(r,c,d))},
nl(a,b,c,d){var s=a.gpQ(),r=this.a
r===$&&A.P()
s.$2(new A.dj(),new A.ei(r,c,d))},
nj(a,b,c,d){var s=a.gpP(),r=this.a
r===$&&A.P()
s.$2(new A.dj(),new A.ei(r,c,d))},
nn(a,b){var s=a.gpR()
this.a===$&&A.P()
s.$1(new A.dj())},
nf(a,b){var s=a.gpN()
this.a===$&&A.P()
s.$1(new A.dj())},
nd(a,b,c,d,e){return A.cg(new A.ma(this,c,b,e,d,a),0)},
n2(a,b){return A.cg(new A.m7(a,b),0)},
n0(a,b){return A.cg(new A.m6(a,b),1)},
mZ(a,b,c){return A.cg(new A.m5(a,b,c),2)}}
A.mf.prototype={
$0(){var s=this,r=s.a.b
r===$&&A.P()
s.c.hc(A.el(r,s.b,null),s.d)},
$S:0}
A.mb.prototype={
$0(){var s,r,q=this,p=q.a.b
p===$&&A.P()
s=q.c.eD(A.el(p,q.b,null),q.d)
p=A.bq(p.buffer,0,null)
r=B.b.Z(q.e,2)
p.$flags&2&&A.B(p)
p[r]=s},
$S:0}
A.mk.prototype={
$0(){var s,r,q,p=this,o=p.a.b
o===$&&A.P()
s=B.o.av(p.c.hd(A.el(o,p.b,null)))
r=s.length
if(r>=p.d)throw A.c(A.c6(14))
o=A.aU(o.buffer,0,null)
q=p.e
B.e.cJ(o,q,s)
o.$flags&2&&A.B(o)
o[q+r]=0},
$S:0}
A.mm.prototype={
$0(){var s,r=this,q=r.a.b
q===$&&A.P()
s=A.aU(q.buffer,r.b,r.c)
q=r.d
if(q!=null)A.wm(s,q.b)
else return A.wm(s,null)},
$S:0}
A.mp.prototype={
$0(){this.a.hf(A.ig(this.b,0))},
$S:0}
A.me.prototype={
$0(){var s,r=Date.now(),q=this.a.b
q===$&&A.P()
s=v.G.BigInt(r)
A.wT(A.wS(q.buffer,0,null),this.c,s,!0)},
$S:0}
A.md.prototype={
$0(){return this.a.eE()},
$S:0}
A.mn.prototype={
$0(){var s=this,r=s.a.b
r===$&&A.P()
s.b.eG(A.aU(r.buffer,s.c,s.d),A.O(v.G.Number(s.e)))},
$S:0}
A.mt.prototype={
$0(){var s=this,r=s.a.b
r===$&&A.P()
s.b.cG(A.aU(r.buffer,s.c,s.d),A.O(v.G.Number(s.e)))},
$S:0}
A.mr.prototype={
$0(){return this.a.dv(A.O(v.G.Number(this.b)))},
$S:0}
A.mq.prototype={
$0(){return this.a.hg(this.b)},
$S:0}
A.mj.prototype={
$0(){var s,r,q=this.b.cF()
if(q>2147483647)throw A.c(A.c6(1802))
s=this.a.b
s===$&&A.P()
s=A.bq(s.buffer,0,null)
r=B.b.Z(this.c,2)
s.$flags&2&&A.B(s)
s[r]=q},
$S:0}
A.mi.prototype={
$0(){var s,r=this.b.cF(),q=this.a.b
q===$&&A.P()
s=v.G.BigInt(r)
A.wT(A.wS(q.buffer,0,null),this.c,s,!0)},
$S:0}
A.ml.prototype={
$0(){return this.a.he(this.b)},
$S:0}
A.ms.prototype={
$0(){return this.a.hh(this.b)},
$S:0}
A.mc.prototype={
$0(){var s,r=this.b.hb(),q=this.a.b
q===$&&A.P()
q=A.bq(q.buffer,0,null)
s=B.b.Z(this.c,2)
q.$flags&2&&A.B(q)
q[s]=r},
$S:0}
A.mg.prototype={
$0(){return this.a.geF()},
$S:4}
A.mh.prototype={
$0(){var s=this.a
if(t.j2.b(s))return s.jD(this.b,this.c)
return 12},
$S:4}
A.mo.prototype={
$0(){var s=this.a
if(t.j2.b(s))return s.geH()
return 4096},
$S:4}
A.m9.prototype={
$0(){var s=this,r=s.a.b
r===$&&A.P()
s.c.$3(s.d,A.el(r,s.b,null),A.O(v.G.Number(s.e)))},
$S:1}
A.m8.prototype={
$0(){var s,r=this.a.b
r===$&&A.P()
s=this.b
return new A.ea(A.ig(B.b.R((A.bq(r.buffer,0,null)[B.b.Z(s,2)]>>>0)+(A.bq(r.buffer,0,null)[B.b.Z(s+4,2)]>>>0)*4294967296,1000),0),this.c)},
$S:122}
A.ma.prototype={
$0(){var s,r,q=this,p=q.a.b
p===$&&A.P()
s=A.qp(p,q.b,q.c)
r=A.qp(p,q.d,q.e)
return q.f.gpF().$2(s,r)},
$S:4}
A.m7.prototype={
$0(){return this.a.$1(this.b)},
$S:4}
A.m6.prototype={
$0(){return this.a.gpH().$1(this.b)},
$S:4}
A.m5.prototype={
$0(){return this.a.gpG().$2(this.b,this.c)},
$S:4}
A.eY.prototype={
B(a,b,c,d){var s,r=null,q={},p=A.Q(A.ve(this.a,v.G.Symbol.asyncIterator,r,r,r,r)),o=A.bH(r,r,r,r,!0,this.$ti.c)
q.a=null
s=new A.l2(q,this,p,o)
o.d=s
o.f=new A.l3(q,o,s)
return new A.a4(o,A.p(o).h("a4<1>")).B(a,b,c,d)},
O(a){return this.B(a,null,null,null)},
az(a,b,c){return this.B(a,null,b,c)},
bq(a,b,c){return this.B(a,b,c,null)}}
A.l2.prototype={
$0(){var s,r=this,q=r.c.next(),p=r.a
p.a=q
s=r.d
A.aq(q,t.m).bc(new A.l4(p,r.b,s,r),s.gfz(),t.P)},
$S:0}
A.l4.prototype={
$1(a){var s,r,q=this,p=a.done
if(p==null)p=null
s=a.value
r=q.c
if(p===!0){r.n()
q.a.a=null}else{r.q(0,s==null?q.b.$ti.c.a(s):s)
q.a.a=null
p=r.b
if(!((p&1)!==0?(r.ga6().e&4)!==0:(p&2)===0))q.d.$0()}},
$S:14}
A.l3.prototype={
$0(){var s,r
if(this.a.a==null){s=this.b
r=s.b
s=!((r&1)!==0?(s.ga6().e&4)!==0:(r&2)===0)}else s=!1
if(s)this.c.$0()},
$S:0}
A.dq.prototype={
u(){var s=0,r=A.i(t.H),q=this,p
var $async$u=A.d(function(a,b){if(a===1)return A.e(b,r)
for(;;)switch(s){case 0:p=q.b
if(p!=null)p.u()
p=q.c
if(p!=null)p.u()
q.c=q.b=null
return A.f(null,r)}})
return A.h($async$u,r)},
gp(){var s=this.a
return s==null?A.r(A.z("Await moveNext() first")):s},
l(){var s,r,q,p=this,o=p.a
if(o!=null)o.continue()
o=new A.l($.o,t.B)
s=new A.L(o,t.ex)
r=p.d
q=t.m
p.b=A.aC(r,"success",new A.ri(p,s),!1,q)
p.c=A.aC(r,"error",new A.rj(p,s),!1,q)
return o}}
A.ri.prototype={
$1(a){var s,r=this.a
r.u()
s=r.$ti.h("1?").a(r.d.result)
r.a=s
this.b.U(s!=null)},
$S:2}
A.rj.prototype={
$1(a){var s=this.a
s.u()
s=s.d.error
if(s==null)s=a
this.b.a9(s)},
$S:2}
A.lM.prototype={
$1(a){this.a.U(this.c.a(this.b.result))},
$S:2}
A.lN.prototype={
$1(a){var s=this.b.error
if(s==null)s=a
this.a.a9(s)},
$S:2}
A.lR.prototype={
$1(a){this.a.U(this.c.a(this.b.result))},
$S:2}
A.lS.prototype={
$1(a){var s=this.b.error
if(s==null)s=a
this.a.a9(s)},
$S:2}
A.lT.prototype={
$1(a){this.a.a9(new A.aW("IndexedDB open blocked"))},
$S:2}
A.mU.prototype={
$1(a){return A.Q(a[1])},
$S:124}
A.pU.prototype={
mS(){var s={}
s.dart=new A.pV(this).$0()
return s},
ej(a){return this.o7(a)},
o7(a){var s=0,r=A.i(t.m),q,p=this,o,n
var $async$ej=A.d(function(b,c){if(b===1)return A.e(c,r)
for(;;)switch(s){case 0:s=3
return A.b(A.aq(v.G.WebAssembly.instantiateStreaming(a,p.mS()),t.m),$async$ej)
case 3:o=c
n=o.instance.exports
if("_initialize" in n)t.g.a(n._initialize).call()
q=o.instance
s=1
break
case 1:return A.f(q,r)}})
return A.h($async$ej,r)}}
A.pV.prototype={
$0(){var s=this.a.a,r=A.Q(v.G.Object),q=A.Q(r.create.apply(r,[null]))
q.error_log=A.bz(s.gof())
q.localtime=A.aY(s.goa())
q.xOpen=A.vU(s.gpl())
q.xDelete=A.kI(s.gp8())
q.xAccess=A.dz(s.goX())
q.xFullPathname=A.dz(s.gph())
q.xRandomness=A.kI(s.gpn())
q.xSleep=A.aY(s.gps())
q.xCurrentTimeInt64=A.aY(s.gp6())
q.xClose=A.bz(s.gp0())
q.xRead=A.dz(s.gpp())
q.xWrite=A.dz(s.gpA())
q.xTruncate=A.aY(s.gpw())
q.xSync=A.aY(s.gpu())
q.xFileSize=A.aY(s.gpd())
q.xFileSize64=A.aY(s.gpf())
q.xLock=A.aY(s.gpj())
q.xUnlock=A.aY(s.gpy())
q.xCheckReservedLock=A.aY(s.goZ())
q.xDeviceCharacteristics=A.bz(s.geF())
q.xFileControl=A.kI(s.gpb())
q.xSectorSize=A.bz(s.geH())
q["dispatch_()v"]=A.bz(s.gna())
q["dispatch_()i"]=A.bz(s.gn3())
q.dispatch_update=A.vU(s.gn8())
q.dispatch_trace=A.dz(s.gn6())
q.dispatch_xFunc=A.dz(s.gng())
q.dispatch_xStep=A.dz(s.gnk())
q.dispatch_xInverse=A.dz(s.gni())
q.dispatch_xValue=A.aY(s.gnm())
q.dispatch_xFinal=A.aY(s.gne())
q.dispatch_compare=A.vU(s.gnc())
q.dispatch_busy=A.aY(s.gn1())
q.changeset_apply_filter=A.aY(s.gn_())
q.changeset_apply_conflict=A.kI(s.gmY())
return q},
$S:18}
A.eh.prototype={}
A.l9.prototype={
eo(){var s=0,r=A.i(t.H),q=this,p,o
var $async$eo=A.d(function(a,b){if(a===1)return A.e(b,r)
for(;;)switch(s){case 0:p=new A.l($.o,t.a7)
o=v.G.indexedDB.open(q.b,1)
o.onupgradeneeded=A.bz(new A.lc(o))
new A.L(p,t.h1).U(A.zZ(o,t.m))
s=2
return A.b(p,$async$eo)
case 2:q.a=b
return A.f(null,r)}})
return A.h($async$eo,r)},
co(a,b){return this.mc(a,b)},
mc(a,b){var s=0,r=A.i(t.H),q=this,p,o,n
var $async$co=A.d(function(c,d){if(c===1)return A.e(d,r)
for(;;)switch(s){case 0:n=q.a
n.toString
p=n.transaction($.zu(),b)
o=A.BP(p)
s=2
return A.b(A.En(new A.lb(a,o,p),t.mj),$async$co)
case 2:s=3
return A.b(o.b.a,$async$co)
case 3:if(o.c){n=q.a
if(n!=null)n.close()
q.a=null}return A.f(null,r)}})
return A.h($async$co,r)},
lT(a){return this.co(new A.la(a),"readwrite")}}
A.lc.prototype={
$1(a){var s=A.Q(this.a.result)
if(J.A(a.oldVersion,0)){s.createObjectStore("files",{autoIncrement:!0}).createIndex("fileName","name",{unique:!0})
s.createObjectStore("blocks")}},
$S:14}
A.lb.prototype={
$0(){var s=0,r=A.i(t.P),q=1,p=[],o=this,n,m,l
var $async$$0=A.d(function(a,b){if(a===1){p.push(b)
s=q}for(;;)switch(s){case 0:q=3
s=6
return A.b(o.a.$1(o.b),$async$$0)
case 6:q=1
s=5
break
case 3:q=2
l=p.pop()
m=o.b
m.d=!0
m.a.abort()
throw l
s=5
break
case 2:s=1
break
case 5:o.c.commit()
return A.f(null,r)
case 1:return A.e(p.at(-1),r)}})
return A.h($async$$0,r)},
$S:40}
A.la.prototype={
$1(a){return this.jE(a)},
jE(a){var s=0,r=A.i(t.H),q=this,p,o,n
var $async$$1=A.d(function(b,c){if(b===1)return A.e(c,r)
for(;;)switch(s){case 0:p=q.a,o=p.length,n=0
case 2:if(!(n<p.length)){s=4
break}s=5
return A.b(p[n].an(a),$async$$1)
case 5:case 3:p.length===o||(0,A.a6)(p),++n
s=2
break
case 4:return A.f(null,r)}})
return A.h($async$$1,r)},
$S:21}
A.hc.prototype={
kP(a){var s=this,r=s.a
r.oncomplete=A.kH(new A.rS(s))
r.onabort=A.kH(new A.rT(s))
r.onerror=A.kH(new A.rU(s))},
fm(a,b,c){var s=t.gk
return v.G.IDBKeyRange.bound(A.u([a,c],s),A.u([a,b],s))},
lX(a){return this.fm(a,9007199254740992,0)},
lY(a,b){return this.fm(a,9007199254740992,b)},
ei(){var s=0,r=A.i(t.dV),q,p=this,o,n,m,l,k
var $async$ei=A.d(function(a,b){if(a===1)return A.e(b,r)
for(;;)switch(s){case 0:l=A.T(t.N,t.S)
k=new A.dq(p.e.index("fileName").openKeyCursor(),t.Q)
case 3:s=5
return A.b(k.l(),$async$ei)
case 5:if(!b){s=4
break}o=k.a
if(o==null)o=A.r(A.z("Await moveNext() first"))
n=o.key
n.toString
A.ak(n)
m=o.primaryKey
m.toString
l.m(0,n,A.O(A.by(m)))
s=3
break
case 4:q=l
s=1
break
case 1:return A.f(q,r)}})
return A.h($async$ei,r)},
ec(a){return this.nz(a)},
nz(a){var s=0,r=A.i(t.I),q,p=this,o
var $async$ec=A.d(function(b,c){if(b===1)return A.e(c,r)
for(;;)switch(s){case 0:o=A
s=3
return A.b(A.bC(p.e.index("fileName").getKey(a),t.i),$async$ec)
case 3:q=o.O(c)
s=1
break
case 1:return A.f(q,r)}})
return A.h($async$ec,r)},
fn(a){return A.bC(this.e.get(a),t.mU).aK(new A.rR(a),t.m)},
cN(a,b){return this.kn(a,b)},
kn(a,b){var s=0,r=A.i(t.oR),q,p=this,o,n,m,l,k,j,i,h,g,f,e
var $async$cN=A.d(function(c,d){if(c===1)return A.e(d,r)
for(;;)switch(s){case 0:s=3
return A.b(p.fn(a),$async$cN)
case 3:h=d
g=h.length
f=new A.bd(new Uint8Array(g),g)
e=new A.dq(p.f.openCursor(p.lX(a)),t.Q)
g=t.a,o=v.G,n=t.c,m=t.H
case 4:s=6
return A.b(e.l(),$async$cN)
case 6:if(!d){s=5
break}l=e.a
if(l==null)l=A.r(A.z("Await moveNext() first"))
k=n.a(l.key)
j=A.O(A.by(k[1]))
if(j>=h.length){s=5
break}i=new A.rV(f,j,Math.min(4096,h.length-j))
if(l.value instanceof o.Blob)b.push(A.od(A.Q(l.value)).aK(i,m))
else i.$1(g.a(l.value))
s=4
break
case 5:q=f
s=1
break
case 1:return A.f(q,r)}})
return A.h($async$cN,r)},
e8(a){return this.mR(a)},
mR(a){var s=0,r=A.i(t.S),q,p=this,o
var $async$e8=A.d(function(b,c){if(b===1)return A.e(c,r)
for(;;)switch(s){case 0:if((p.b.a.a&30)!==0)A.r(A.z("IDB transaction already completed"))
o=A
s=3
return A.b(A.bC(p.e.put({name:a,length:0}),t.i),$async$e8)
case 3:q=o.O(c)
s=1
break
case 1:return A.f(q,r)}})
return A.h($async$e8,r)},
cc(a,b){return this.oS(a,b)},
oS(a,b){var s=0,r=A.i(t.H),q=this,p,o,n,m,l
var $async$cc=A.d(function(c,d){if(c===1)return A.e(d,r)
for(;;)switch(s){case 0:if((q.b.a.a&30)!==0)A.r(A.z("IDB transaction already completed"))
s=2
return A.b(q.fn(a),$async$cc)
case 2:p=d
o=b.b
n=A.p(o).h("b2<1>")
m=A.an(new A.b2(o,n),n.h("m.E"))
B.c.kl(m)
s=3
return A.b(A.n4(new A.a8(m,new A.rW(new A.rX(q,a),b),A.a5(m).h("a8<1,n<~>>")),t.H),$async$cc)
case 3:s=b.c!==p.length?4:5
break
case 4:l=new A.dq(q.e.openCursor(a),t.Q)
s=6
return A.b(l.l(),$async$cc)
case 6:s=7
return A.b(A.bC(l.gp().update({name:p.name,length:b.c}),t.X),$async$cc)
case 7:case 5:return A.f(null,r)}})
return A.h($async$cc,r)},
cb(a,b,c){return this.oJ(0,b,c)},
oJ(a,b,c){var s=0,r=A.i(t.H),q=this,p,o
var $async$cb=A.d(function(d,e){if(d===1)return A.e(e,r)
for(;;)switch(s){case 0:if((q.b.a.a&30)!==0)A.r(A.z("IDB transaction already completed"))
s=2
return A.b(q.fn(b),$async$cb)
case 2:p=e
s=p.length>c?3:4
break
case 3:s=5
return A.b(A.bC(q.f.delete(q.lY(b,B.b.R(c,4096)*4096)),t.X),$async$cb)
case 5:case 4:o=new A.dq(q.e.openCursor(b),t.Q)
s=6
return A.b(o.l(),$async$cb)
case 6:s=7
return A.b(A.bC(o.gp().update({name:p.name,length:c}),t.X),$async$cb)
case 7:return A.f(null,r)}})
return A.h($async$cb,r)},
ea(a){return this.mX(a)},
mX(a){var s=0,r=A.i(t.H),q=this,p
var $async$ea=A.d(function(b,c){if(b===1)return A.e(c,r)
for(;;)switch(s){case 0:if((q.b.a.a&30)!==0)A.r(A.z("IDB transaction already completed"))
p=t.X
s=2
return A.b(A.n4(A.u([A.bC(q.f.delete(q.fm(a,9007199254740992,0)),p),A.bC(q.e.delete(a),p)],t.M),t.H),$async$ea)
case 2:return A.f(null,r)}})
return A.h($async$ea,r)}}
A.rS.prototype={
$0(){this.a.b.L()},
$S:1}
A.rT.prototype={
$0(){var s=this.a,r=s.b
if((r.a.a&30)===0)if(s.d)r.L()
else{s=s.a.error
r.a9(s==null?new v.G.DOMException("IDB transaction aborted"):s)}},
$S:1}
A.rU.prototype={
$0(){var s=this.a,r=s.b
if((r.a.a&30)===0){s=s.a.error
r.a9(s==null?new v.G.DOMException("IDB transaction error"):s)}},
$S:1}
A.rR.prototype={
$1(a){if(a==null)throw A.c(A.aZ(this.a,"fileId","File not found in database"))
else return a},
$S:126}
A.rV.prototype={
$1(a){var s=this.a
s.cJ(s,this.b,J.cO(a,0,this.c))},
$S:127}
A.rX.prototype={
k_(a,b){var s=0,r=A.i(t.H),q=this,p,o,n,m,l,k
var $async$$2=A.d(function(c,d){if(c===1)return A.e(d,r)
for(;;)switch(s){case 0:p=q.a.f
o=q.b
n=t.gk
s=2
return A.b(A.bC(p.openCursor(v.G.IDBKeyRange.only(A.u([o,a],n))),t.mU),$async$$2)
case 2:m=d
l=t.a.a(B.e.gau(b))
k=t.X
s=m==null?3:5
break
case 3:s=6
return A.b(A.bC(p.put(l,A.u([o,a],n)),k),$async$$2)
case 6:s=4
break
case 5:s=7
return A.b(A.bC(m.update(l),k),$async$$2)
case 7:case 4:return A.f(null,r)}})
return A.h($async$$2,r)},
$2(a,b){return this.k_(a,b)},
$S:128}
A.rW.prototype={
$1(a){var s=this.b.b.i(0,a)
s.toString
return this.a.$2(a,s)},
$S:129}
A.ru.prototype={
mr(a,b,c){B.e.cJ(this.b.cB(a,new A.rv(this,a)),b,c)},
mJ(a,b){var s,r,q,p,o,n,m,l
for(s=b.length,r=0;r<s;r=l){q=a+r
p=B.b.R(q,4096)
o=B.b.aS(q,4096)
n=s-r
if(o!==0)m=Math.min(4096-o,n)
else{m=Math.min(4096,n)
o=0}l=r+m
this.mr(p*4096,o,J.cO(B.e.gau(b),b.byteOffset+r,m))}this.c=Math.max(this.c,a+s)}}
A.rv.prototype={
$0(){var s=new Uint8Array(4096),r=this.a.a,q=r.length,p=this.b
if(q>p)B.e.cJ(s,0,J.cO(B.e.gau(r),r.byteOffset+p,Math.min(4096,q-p)))
return s},
$S:130}
A.k8.prototype={}
A.cn.prototype={
d1(a){var s=this
if(s.e||s.d.a==null)A.r(A.c6(10))
if(a.fS(s.x)){s.c3(!0)
return a.d.a}else return A.n2(null,t.H)},
c3(a){return this.mk(a)},
mk(a){var s=0,r=A.i(t.H),q,p=this,o,n
var $async$c3=A.d(function(b,c){if(b===1)return A.e(c,r)
for(;;)switch(s){case 0:if(a&&!p.r){s=1
break}s=p.f==null&&!p.x.gE(0)?3:4
break
case 3:o=p.x
n=A.an(o,o.$ti.h("m.E"))
o.aF(0)
o=p.d.lT(n).J(new A.nv(p,n,a))
p.f=o
s=5
return A.b(o,$async$c3)
case 5:case 4:case 1:return A.f(q,r)}})
return A.h($async$c3,r)},
n(){var s=0,r=A.i(t.H),q,p=this,o,n
var $async$n=A.d(function(a,b){if(a===1)return A.e(b,r)
for(;;)switch(s){case 0:if(!p.e){o=p.d1(new A.ha(new A.nw(),new A.L(new A.l($.o,t.D),t.F)))
p.e=!0
p.c3(!1)
q=o
s=1
break}else{n=p.x
if(!n.gE(0)){q=n.gaP(0).d.a
s=1
break}}case 1:return A.f(q,r)}})
return A.h($async$n,r)},
cl(a,b){return this.ll(a,b)},
ll(a,b){var s=0,r=A.i(t.S),q,p=this,o,n
var $async$cl=A.d(function(c,d){if(c===1)return A.e(d,r)
for(;;)switch(s){case 0:n=p.z
s=n.F(b)?3:5
break
case 3:n=n.i(0,b)
n.toString
q=n
s=1
break
s=4
break
case 5:s=6
return A.b(a.ec(b),$async$cl)
case 6:o=d
o.toString
n.m(0,b,o)
q=o
s=1
break
case 4:case 1:return A.f(q,r)}})
return A.h($async$cl,r)},
cV(){var s=0,r=A.i(t.H),q=this,p
var $async$cV=A.d(function(a,b){if(a===1)return A.e(b,r)
for(;;)switch(s){case 0:p=A.u([],t.M)
s=2
return A.b(q.d.co(new A.nu(q,p),"readonly"),$async$cV)
case 2:s=3
return A.b(A.v9(p,t.H),$async$cV)
case 3:return A.f(null,r)}})
return A.h($async$cV,r)},
j2(){var s=this.f
return s==null?this.c3(!1):s},
eD(a,b){return this.w.d.F(a)?1:0},
hc(a,b){var s=this
s.w.d.H(0,a)
if(!s.y.H(0,a))s.d1(new A.h5(s,a,new A.L(new A.l($.o,t.D),t.F)))},
hd(a){return new v.G.URL(a,"file:///").pathname},
cd(a,b){var s,r,q,p=this,o=a.a
if(o==null)o=A.wF(p.b,"/")
s=p.w
r=s.d.F(o)?1:0
q=s.cd(new A.fH(o),b)
if(r===0)if((b&8)!==0)p.y.q(0,o)
else p.d1(new A.er(p,o,new A.L(new A.l($.o,t.D),t.F)))
return new A.eE(new A.k1(p,q.a,o),0)},
hf(a){}}
A.nv.prototype={
$0(){var s,r,q,p,o=this.a
o.f=null
for(s=this.b,r=s.length,q=0;q<s.length;s.length===r||(0,A.a6)(s),++q){p=s[q].d.a
if((p.a&30)!==0)A.r(A.z("Future already completed"))
p.bf(null)}o.c3(this.c)},
$S:1}
A.nw.prototype={
$1(a){return this.jK(a)},
jK(a){var s=0,r=A.i(t.H)
var $async$$1=A.d(function(b,c){if(b===1)return A.e(c,r)
for(;;)switch(s){case 0:a.c=!0
return A.f(null,r)}})
return A.h($async$$1,r)},
$S:21}
A.nu.prototype={
$1(a){return this.jJ(a)},
jJ(a){var s=0,r=A.i(t.H),q=this,p,o,n,m,l,k,j
var $async$$1=A.d(function(b,c){if(b===1)return A.e(c,r)
for(;;)switch(s){case 0:s=2
return A.b(a.ei(),$async$$1)
case 2:m=c
l=q.a
l.z.a7(0,m)
p=m.gbm(),p=p.gA(p),o=q.b,l=l.w.d
case 3:if(!p.l()){s=4
break}n=p.gp()
k=l
j=n.a
s=5
return A.b(a.cN(n.b,o),$async$$1)
case 5:k.m(0,j,c)
s=3
break
case 4:return A.f(null,r)}})
return A.h($async$$1,r)},
$S:21}
A.k1.prototype={
eG(a,b){this.b.eG(a,b)},
geF(){return 0},
geH(){return 4096},
hb(){return this.b.d>=2?1:0},
eE(){},
cF(){return this.b.cF()},
he(a){this.b.d=a
return null},
hg(a){},
jD(a,b){return 12},
dv(a){var s=this,r=s.a
if(r.e||r.d.a==null)A.r(A.c6(10))
s.b.dv(a)
if(!r.y.V(0,s.c))r.d1(new A.ha(new A.rQ(s,a),new A.L(new A.l($.o,t.D),t.F)))},
hh(a){this.b.d=a
return null},
cG(a,b){var s,r,q,p,o,n,m=this,l=m.a
if(l.e||l.d.a==null)A.r(A.c6(10))
s=m.c
if(l.y.V(0,s)){m.b.cG(a,b)
return}r=l.w.d.i(0,s)
if(r==null)r=new A.bd(new Uint8Array(0),0)
q=J.cO(B.e.gau(r.a),0,r.b)
m.b.cG(a,b)
p=new Uint8Array(a.length)
B.e.cJ(p,0,a)
o=A.u([],t.o6)
n=$.o
o.push(new A.k8(b,p))
l.d1(new A.eL(l,s,q,o,new A.L(new A.l(n,t.D),t.F)))},
$iaO:1,
$ifW:1}
A.rQ.prototype={
$1(a){return this.jZ(a)},
jZ(a){var s=0,r=A.i(t.H),q,p=this,o,n
var $async$$1=A.d(function(b,c){if(b===1)return A.e(c,r)
for(;;)switch(s){case 0:o=p.a
n=a
s=3
return A.b(o.a.cl(a,o.c),$async$$1)
case 3:q=n.cb(0,c,p.b)
s=1
break
case 1:return A.f(q,r)}})
return A.h($async$$1,r)},
$S:21}
A.aD.prototype={
fS(a){a.dM(a.c,this,!1)
return!0}}
A.ha.prototype={
an(a){return this.w.$1(a)}}
A.h5.prototype={
fS(a){var s,r,q,p
if(!a.gE(0)){s=a.gaP(0)
for(r=this.x;s!=null;)if(s instanceof A.h5)if(s.x===r)return!1
else s=s.gdm()
else if(s instanceof A.eL){q=s.gdm()
if(s.x===r){p=s.a
p.toString
p.ft(A.p(s).h("aG.E").a(s))}s=q}else if(s instanceof A.er){if(s.x===r){r=s.a
r.toString
r.ft(A.p(s).h("aG.E").a(s))
return!1}s=s.gdm()}else break}a.dM(a.c,this,!1)
return!0},
an(a){return this.oE(a)},
oE(a){var s=0,r=A.i(t.H),q=this,p,o,n
var $async$an=A.d(function(b,c){if(b===1)return A.e(c,r)
for(;;)switch(s){case 0:p=q.w
o=q.x
s=2
return A.b(p.cl(a,o),$async$an)
case 2:n=c
p.z.H(0,o)
s=3
return A.b(a.ea(n),$async$an)
case 3:return A.f(null,r)}})
return A.h($async$an,r)}}
A.er.prototype={
an(a){return this.oD(a)},
oD(a){var s=0,r=A.i(t.H),q=this,p,o,n
var $async$an=A.d(function(b,c){if(b===1)return A.e(c,r)
for(;;)switch(s){case 0:p=q.x
o=q.w.z
n=p
s=2
return A.b(a.e8(p),$async$an)
case 2:o.m(0,n,c)
return A.f(null,r)}})
return A.h($async$an,r)}}
A.eL.prototype={
fS(a){var s,r=a.b===0?null:a.gaP(0)
for(s=this.x;r!=null;)if(r instanceof A.eL)if(r.x===s){B.c.a7(r.z,this.z)
return!1}else r=r.gdm()
else if(r instanceof A.er){if(r.x===s)break
r=r.gdm()}else break
a.dM(a.c,this,!1)
return!0},
an(a){return this.oF(a)},
oF(a){var s=0,r=A.i(t.H),q=this,p,o,n,m,l,k
var $async$an=A.d(function(b,c){if(b===1)return A.e(c,r)
for(;;)switch(s){case 0:m=q.y
l=new A.ru(m,A.T(t.S,t.p),m.length)
for(m=q.z,p=m.length,o=0;o<m.length;m.length===p||(0,A.a6)(m),++o){n=m[o]
l.mJ(n.a,n.b)}k=a
s=3
return A.b(q.w.cl(a,q.x),$async$an)
case 3:s=2
return A.b(k.cc(c,l),$async$an)
case 2:return A.f(null,r)}})
return A.h($async$an,r)}}
A.dS.prototype={
aE(){return"FileType."+this.b}}
A.e7.prototype={
b6(){var s=this.d
if(s!=null)return s
throw A.c(A.z("VFS closed"))},
eD(a,b){var s=$.v0().i(0,a)
if(s==null)return this.e.d.F(a)?1:0
else return this.b6().iY(s)?1:0},
hc(a,b){var s=$.v0().i(0,a)
if(s==null){this.e.d.H(0,a)
return null}else this.b6().jg(s,!1,b!==0)},
hd(a){return new v.G.URL(a,"file:///").pathname},
cd(a,b){var s,r,q=this,p=a.a
if(p==null)return q.e.cd(a,b)
s=$.v0().i(0,p)
if(s==null)return q.e.cd(a,b)
r=q.b6()
if(!r.iY(s))if((b&4)!==0){r.c6(s).truncate(0)
r.el(s,!0)}else throw A.c(B.bV)
return new A.eE(new A.kq(q,s,(b&8)!==0),0)},
hf(a){},
n(){var s=this.d
if(s!=null){s.b.close()
s.c.close()
s.d.close()}this.d=null},
bL(a,b){return this.oo(a,b)},
om(a){return this.bL(a,!1)},
oo(a,b){var s=0,r=A.i(t.H),q=this,p,o,n,m,l,k
var $async$bL=A.d(function(c,d){if(c===1)return A.e(d,r)
for(;;)switch(s){case 0:m=new A.ox(a,b)
s=2
return A.b(m.$1("meta"),$async$bL)
case 2:l=d
k=J.A(l.getSize(),0)
l.truncate(2)
s=3
return A.b(m.$1("database"),$async$bL)
case 3:p=d
s=4
return A.b(m.$1("journal"),$async$bL)
case 4:o=d
n=q.d=new A.ta(new Uint8Array(2),l,p,o)
if(k){n.el(B.a8,p.getSize()>0)
n.el(B.a9,o.getSize()>0)}return A.f(null,r)}})
return A.h($async$bL,r)}}
A.ox.prototype={
jM(a){var s=0,r=A.i(t.m),q,p=this,o,n
var $async$$1=A.d(function(b,c){if(b===1)return A.e(c,r)
for(;;)switch(s){case 0:o=t.m
s=3
return A.b(A.aq(p.a.getFileHandle(a,{create:!0}),o),$async$$1)
case 3:n=c
s=4
return A.b(A.aq(p.b?n.createSyncAccessHandle({mode:"readwrite-unsafe"}):n.createSyncAccessHandle(),o),$async$$1)
case 4:q=c
s=1
break
case 1:return A.f(q,r)}})
return A.h($async$$1,r)},
$1(a){return this.jM(a)},
$S:131}
A.kq.prototype={
jo(a,b){return A.wC(this.a.b6().c6(this.b),a,{at:b})},
hb(){return this.d>=2?1:0},
eE(){var s=this.a,r=this.b
s.b6().c6(r).flush()
if(this.c)s.b6().el(r,!1)},
cF(){return this.a.b6().c6(this.b).getSize()},
he(a){this.d=a},
hg(a){this.a.b6().c6(this.b).flush()},
dv(a){this.a.b6().c6(this.b).truncate(a)},
hh(a){this.d=a},
cG(a,b){if(A.wD(this.a.b6().c6(this.b),a,{at:b})<a.length)throw A.c(B.bX)}}
A.ta.prototype={
iY(a){var s=this.a
if(A.wC(this.b,s,{at:0})!==s.length)A.r(A.c6(10))
return s[a.a]!==0},
jg(a,b,c){var s=this.a,r=b?1:0
s.$flags&2&&A.B(s)
s[a.a]=r
r=this.b
if(A.wD(r,s,{at:0})!==s.length)A.r(A.c6(10))
if(c)r.flush()},
el(a,b){return this.jg(a,b,!1)},
c6(a){var s
switch(a.a){case 0:s=this.c
break
case 1:s=this.d
break
default:s=null}return s}}
A.pO.prototype={
kL(a,b){var s=this,r=s.c
r.a!==$&&A.yT()
r.a=s
A.jY(new A.pP(s),t.h6)
r=t.S
A.jY(new A.pQ(s),r)
s.r=A.jY(new A.pR(s),r)
s.w=A.jY(new A.pS(s),r)},
d3(a,b){var s=a.length,r=this.ek(s+b),q=A.aU(this.b.buffer,0,null)
s=r+s
B.e.af(q,r,s,a)
B.e.fJ(q,s,s+b,0)
return r},
fB(a){return this.d3(a,0)},
ek(a){var s=this.d.dart_sqlite3_malloc(a)
if(s===0)throw A.c(A.z("out of wasm memory"))
return s},
iU(a,b){var s=b==null?null:b
return this.d.dart_sqlite3_updates(a,s)},
iS(a,b){var s=b==null?null:b
return this.d.dart_sqlite3_commits(a,s)},
iT(a,b){var s=b==null?null:b
return this.d.dart_sqlite3_rollbacks(a,s)}}
A.pP.prototype={
$1(a){a.pI(this.a)},
$S:132}
A.pQ.prototype={
$1(a){return this.a.d.sqlite3session_delete(a)},
$S:8}
A.pR.prototype={
$1(a){return this.a.d.sqlite3_close_v2(a)},
$S:8}
A.pS.prototype={
$1(a){return this.a.d.sqlite3_finalize(a)},
$S:8}
A.dN.prototype={}
A.o5.prototype={
hp(a){var s,r=this,q=r.a
q.start()
r.c=A.aC(q,"message",new A.o9(r),!1,t.m)
s=a.b
if(a.c==null&&s!=null){q=$.hM()
q.toString
A.ej(q,s,null,null,!1).aK(new A.oa(r),t.P)}},
fg(a){return this.lp(a)},
lp(a){var s=0,r=A.i(t.H),q=this
var $async$fg=A.d(function(b,c){if(b===1)return A.e(c,r)
for(;;)switch(s){case 0:A.DQ(a,new A.o6(q),q.gj6(),new A.o7(q),new A.o8(q))
return A.f(null,r)}})
return A.h($async$fg,r)},
bP(a,b,c,d){return this.kk(a,b,c,d,d)},
ce(a,b,c){return this.bP(a,b,null,c)},
kk(a,b,c,d,e){var s=0,r=A.i(e),q,p=this,o,n,m,l
var $async$bP=A.d(function(f,g){if(f===1)return A.e(g,r)
for(;;)switch(s){case 0:l={}
if((p.b.a.a&30)!==0)throw A.c(A.zQ(null))
o=p.e++
n=new A.l($.o,t.a7)
p.f.m(0,o,new A.L(n,t.h1))
a.i=o
p.a.postMessage(a,A.dE(a))
l.a=!1
if(c!=null)c.J(new A.ob(l,p,o))
s=3
return A.b(n,$async$bP)
case 3:m=g
l.a=!0
if(J.A(m.t,b.b)){q=d.a(m)
s=1
break}else throw A.c(A.AU(m))
case 1:return A.f(q,r)}})
return A.h($async$bP,r)},
lE(a){var s,r,q=this,p=q.b
if((p.a.a&30)!==0)return
q.a.postMessage("_disconnect")
s=q.c
if(s!=null)s.u()
s=q.d
if(s!=null)s.u()
for(s=q.f,r=new A.b3(s,s.r,s.e);r.l();)r.d.a9(new A.f1(a))
s.aF(0)
p.L()},
i1(){return this.lE(null)}}
A.o9.prototype={
$1(a){if(a.data=="_disconnect"){this.a.i1()
return}this.a.fg(A.Q(a.data))},
$S:2}
A.oa.prototype={
$1(a){this.a.i1()
a.a.L()},
$S:133}
A.o8.prototype={
$1(a){var s=this.a.f.H(0,a.i)
if(s!=null)s.U(a)},
$S:14}
A.o7.prototype={
$1(a){return this.jL(a)},
jL(a1){var s=0,r=A.i(t.P),q=1,p=[],o=[],n=this,m,l,k,j,i,h,g,f,e,d,c,b,a,a0
var $async$$1=A.d(function(a2,a3){if(a2===1){p.push(a3)
s=q}for(;;)switch(s){case 0:f=null
e=a1.i
d=n.a
c=d.r
b=v.G
a=new b.AbortController()
c.m(0,e,a)
m=a
q=3
j=d.n5(a1,m.signal)
s=6
return A.b(t.nW.b(j)?j:A.bL(j,t.m),$async$$1)
case 6:f=a3
o.push(5)
s=4
break
case 3:q=2
a0=p.pop()
l=A.E(a0)
k=A.M(a0)
if(!(l instanceof A.bm)){b.console.error("Error in worker: "+J.bb(l))
b.console.error("Original trace: "+A.q(k))}b=l
if(b instanceof A.dc){h=A.A9(b)
g=0}else{g=b instanceof A.bm?1:null
h=null}f={e:J.bb(b),s:g,r:h,i:e,t:"errorResponse"}
o.push(5)
s=4
break
case 2:o=[1]
case 4:q=1
c.H(0,e)
s=o.pop()
break
case 5:c=f
d.a.postMessage(c,A.dE(c))
return A.f(null,r)
case 1:return A.e(p.at(-1),r)}})
return A.h($async$$1,r)},
$S:134}
A.o6.prototype={
$1(a){var s=this.a.r.H(0,a.i)
if(s!=null)s.abort()},
$S:14}
A.ob.prototype={
$0(){if(!this.a.a){var s={i:this.c,t:"abort"}
this.b.a.postMessage(s,A.dE(s))}},
$S:1}
A.f1.prototype={
j(a){return"Channel to database worker is closed: "+A.q(this.a)},
$iJ:1}
A.jS.prototype={}
A.j1.prototype={
kG(a,b){var s,r=this
r.a.b.a.aK(new A.oj(r),t.P)
s=r.e
s.a=new A.ok(r)
s.b=new A.ol(r)
r.il(r.f,new A.om(r),"notifyCommit")
r.il(r.r,new A.on(r),"notifyRollback")},
il(a,b,c){var s=a.b
s.a=new A.oh(this,a,c,b)
s.b=new A.oi(this,a,b)},
aX(a){var s=0,r=A.i(t.X),q,p=this
var $async$aX=A.d(function(b,c){if(b===1)return A.e(c,r)
for(;;)switch(s){case 0:s=3
return A.b(p.a.bP({r:a,z:null,i:0,d:p.b,t:"custom"},B.q,null,t.m),$async$aX)
case 3:q=c.r
s=1
break
case 1:return A.f(q,r)}})
return A.h($async$aX,r)},
cC(a,b,c){return this.oB(a,b,c,c)},
oB(a,b,c,d){var s=0,r=A.i(d),q,p=2,o=[],n=[],m=this,l,k,j,i,h,g,f
var $async$cC=A.d(function(e,a0){if(e===1){o.push(a0)
s=p}for(;;)switch(s){case 0:k=m.a
j=m.b
i=t.m
g=A
f=A
s=3
return A.b(k.bP({i:0,d:j,t:"exclusiveLock"},B.q,b,i),$async$cC)
case 3:h=g.O(f.by(a0.r))
p=4
s=7
return A.b(a.$1(h),$async$cC)
case 7:l=a0
q=l
n=[1]
s=5
break
n.push(6)
s=5
break
case 4:n=[2]
case 5:p=2
s=8
return A.b(k.ce({z:h,i:0,d:j,t:"releaseLock"},B.q,i),$async$cC)
case 8:s=n.pop()
break
case 6:case 1:return A.f(q,r)
case 2:return A.e(o.at(-1),r)}})
return A.h($async$cC,r)},
cI(a,b,c,d){return this.kf(a,b,c,d)},
kf(a,b,c,d){var s=0,r=A.i(t.ii),q,p=this,o,n,m,l,k
var $async$cI=A.d(function(e,f){if(e===1)return A.e(f,r)
for(;;)switch(s){case 0:m=A.vr(c)
l=d==null?null:d
s=3
return A.b(p.a.bP({s:a,p:m.a,v:m.b,z:l,r:!0,c:b,i:0,d:p.b,t:"runQuery"},B.bz,null,t.m),$async$cI)
case 3:k=f
l=k.x
o=k.y
n=A.AW(k)
n.toString
q=new A.kg(l,o,n)
s=1
break
case 1:return A.f(q,r)}})
return A.h($async$cI,r)},
$iww:1}
A.oj.prototype={
$1(a){var s=this.a,r=s.c
if((r.a.a&30)===0){s=A.u([s.e.n(),s.r.b.n(),s.f.b.n()],t.en)
r.U(A.v9(s,t.z))}},
$S:9}
A.ok.prototype={
$0(){var s,r=this.a
if(r.d==null){s=r.a.w
r.d=new A.ao(s,A.p(s).h("ao<1>")).O(new A.of(r))}if((r.c.a.a&30)===0)r.a.ce({a:!0,i:0,d:r.b,t:"updateRequest"},B.q,t.m)},
$S:0}
A.of.prototype={
$1(a){var s
if(J.A(a.t,"notifyUpdate")){s=this.a
if(J.A(a.d,s.b))s.e.q(0,new A.b7(B.bs[a.k],a.u,a.r))}},
$S:2}
A.ol.prototype={
$0(){var s=this.a,r=s.d
if(r!=null)r.u()
s.d=null
if((s.c.a.a&30)===0)s.a.ce({a:!1,i:0,d:s.b,t:"updateRequest"},B.q,t.m)},
$S:1}
A.om.prototype={
$1(a){return{a:a,i:0,d:this.a.b,t:"commitRequest"}},
$S:49}
A.on.prototype={
$1(a){return{a:a,i:0,d:this.a.b,t:"rollbackRequest"}},
$S:49}
A.oh.prototype={
$0(){var s,r,q=this,p=q.b
if(p.a==null){s=q.a
r=s.a.w
p.a=new A.ao(r,A.p(r).h("ao<1>")).O(new A.og(s,q.c,p))}p=q.a
if((p.c.a.a&30)===0)p.a.ce(q.d.$1(!0),B.q,t.m)},
$S:0}
A.og.prototype={
$1(a){if(J.A(a.t,this.b)&&J.A(a.d,this.a.b))this.c.b.q(0,null)},
$S:2}
A.oi.prototype={
$0(){var s=this.b,r=s.a
if(r!=null)r.u()
s.a=null
s=this.a
if((s.c.a.a&30)===0)s.a.ce(this.c.$1(!1),B.q,t.m)},
$S:1}
A.jF.prototype={
aZ(a,b){return this.nI(a,b)},
nI(a,b){var s=0,r=A.i(t.m),q,p=this
var $async$aZ=A.d(function(c,d){if(c===1)return A.e(d,r)
for(;;)switch(s){case 0:s=3
return A.b(p.x.$1(a.r),$async$aZ)
case 3:q={r:d,i:a.i,t:"simpleSuccessResponse"}
s=1
break
case 1:return A.f(q,r)}})
return A.h($async$aZ,r)},
fK(a){this.w.q(0,a)}}
A.mu.prototype={
fC(a){var s=0,r=A.i(t.kS),q,p=this,o
var $async$fC=A.d(function(b,c){if(b===1)return A.e(c,r)
for(;;)switch(s){case 0:o={port:a.a,lockName:a.b}
q=A.AR(A.Bn(new A.dN(o.port,o.lockName,null),p.d),0)
s=1
break
case 1:return A.f(q,r)}})
return A.h($async$fC,r)}}
A.mv.prototype={
br(a){return this.o8(a)},
o8(a){var s=0,r=A.i(t.w),q
var $async$br=A.d(function(b,c){if(b===1)return A.e(c,r)
for(;;)switch(s){case 0:q=A.pX(a,null)
s=1
break
case 1:return A.f(q,r)}})
return A.h($async$br,r)}}
A.ia.prototype={}
A.m4.prototype={}
A.cB.prototype={
n(){this.gd5().n()}}
A.rm.prototype={}
A.io.prototype={
em(){var s=0,r=A.i(t.H),q=this
var $async$em=A.d(function(a,b){if(a===1)return A.e(b,r)
for(;;)switch(s){case 0:s=!q.c?2:3
break
case 2:s=4
return A.b(q.a.om(q.b),$async$em)
case 4:case 3:return A.f(null,r)}})
return A.h($async$em,r)},
h3(){var s=0,r=A.i(t.H),q=this
var $async$h3=A.d(function(a,b){if(a===1)return A.e(b,r)
for(;;)switch(s){case 0:if(!q.c)q.a.n()
return A.f(null,r)}})
return A.h($async$h3,r)}}
A.n7.prototype={
oG(a){var s=this.a,r=this.d
if(this.c)return s.transfer(r)
else return s.slice(0,r)},
lB(a){var s,r,q,p=this,o=p.b
for(s=o;s<a;){s*=2
p.b=s}if(p.c)p.a=p.a.transfer(s)
else{r=v.G
q=new r.ArrayBuffer(s)
new r.Uint8Array(q,0,p.b).set(new r.Uint8Array(p.a,0,o))
p.a=q}}}
A.q6.prototype={
$1(a){var s=new A.l($.o,t.D),r=new A.bV(new A.L(s,t.F))
this.a.a=r
this.b.U(r)
return A.wE(s)},
$S:50}
A.q7.prototype={
$2(a,b){var s,r,q
A.Q(a)
s=J.A(a.name,"AbortError")
r=this.a.a
if(r!=null){if((r.a.a.a&30)===0){q=this.b
if(q!=null)q.$0()}}else{q=this.c
if(s)q.b8(new A.bm("Operation was cancelled",null),b)
else q.b8(a,b)}return null},
$S:137}
A.bV.prototype={}
A.ic.prototype={
gmL(){if(this.d.a)return!1
return!this.e||this.r!=null},
bS(a){return this.kV(a)},
kV(a){var s=0,r=A.i(t.H),q=1,p=[],o=[],n=this,m,l,k,j,i,h,g
var $async$bS=A.d(function(b,c){if(b===1){p.push(c)
s=q}for(;;)switch(s){case 0:h=$.hM()
h.toString
m=h
l=null
k=null
j=null
q=3
s=6
return A.b(A.ej(m,n.c,a,null,!1),$async$bS)
case 6:l=c
s=7
return A.b(A.ej(m,n.a,null,n.gls(),!0),$async$bS)
case 7:k=c
s=8
return A.b(A.ej(m,n.b,a,null,!1),$async$bS)
case 8:j=c
h=n.f
h=h==null?null:h.em()
s=9
return A.b(h instanceof A.l?h:A.bL(h,t.H),$async$bS)
case 9:n.r=new A.N(k,j)
o.push(5)
s=4
break
case 3:q=2
g=p.pop()
h=k
if(h!=null)h.a.L()
h=j
if(h!=null)h.a.L()
throw g
o.push(5)
s=4
break
case 2:o=[1]
case 4:q=1
h=l
if(h!=null)h.a.L()
s=o.pop()
break
case 5:return A.f(null,r)
case 1:return A.e(p.at(-1),r)}})
return A.h($async$bS,r)},
lt(){this.js()},
fW(a,b,c){return this.d.ez(new A.mI(this,a,b,c),b,c)},
js(){return this.d.ha(new A.mJ(this),t.H)}}
A.mI.prototype={
$0(){var s,r=this,q=r.a
if(!q.e||q.r!=null)return r.b.$0()
s=r.d
return q.bS(r.c).aK(new A.mH(r.b,s),s)},
$S(){return this.d.h("0/()")}}
A.mH.prototype={
$1(a){return this.a.$0()},
$S(){return this.b.h("0/(~)")}}
A.mJ.prototype={
$0(){var s,r,q,p=this.a,o=p.r
if(o!=null){s=o.a
r=o.b
q=p.f
if(q!=null)q.h3()
s.a.L()
r.a.L()
p.r=null}},
$S:1}
A.dZ.prototype={
ez(a,b,c){return this.oR(a,b,c,c)},
ha(a,b){return this.ez(a,null,b)},
oR(a,b,c,d){var s=0,r=A.i(d),q,p=this,o,n,m,l,k,j,i,h,g
var $async$ez=A.d(function(e,f){if(e===1)return A.e(f,r)
for(;;)switch(s){case 0:h={}
g=b==null
if(J.A(g?null:b.aborted,!0))throw A.c(B.B)
h.a=!1
o=new A.nY(h,p)
if(!p.a){h.a=p.a=!0
q=A.dT(a,c).J(o)
s=1
break}else{n={}
m=new A.l($.o,c.h("l<0>"))
l=new A.L(m,c.h("L<0>"))
n.a=null
h=new A.nX(h,n,l,a,c)
if(!g)n.a=A.aC(b,"abort",new A.nW(n,p,l,h),!1,t.m)
g=p.b
n=g.a
k=g.c
n[k]=h
n=n.length
k=(k+1&n-1)>>>0
g.c=k
if(g.b===k){j=A.b4(n*2,null,!1,g.$ti.h("1?"))
h=g.a
n=g.b
i=h.length-n
B.c.Y(j,0,i,h,n)
B.c.Y(j,i,i+g.b,g.a,0)
g.b=0
g.c=g.a.length
g.a=j}++g.d
q=m.J(o)
s=1
break}case 1:return A.f(q,r)}})
return A.h($async$ez,r)}}
A.nY.prototype={
$0(){var s,r,q,p
if(!this.a.a)return
s=this.b
r=s.b
if(!r.gE(0)){s=r.b
if(s===r.c)A.r(A.bW());++r.d
q=r.a
p=q[s]
if(p==null)p=r.$ti.c.a(p)
q[s]=null
r.b=(s+1&q.length-1)>>>0
p.$0()}else s.a=!1},
$S:0}
A.nX.prototype={
$0(){var s,r=this
r.a.a=!0
s=r.b.a
if(s!=null)s.u()
r.c.U(A.dT(r.d,r.e))},
$S:0}
A.nW.prototype={
$1(a){var s,r=this
r.a.a.u()
s=r.c
if((s.a.a&30)===0){r.b.b.H(0,r.d)
s.a9(B.B)}},
$S:2}
A.cW.prototype={
gjx(){var s,r,q,p,o,n=this,m=t.s,l=A.u([],m)
for(s=n.a,r=s.length,q=0;q<s.length;s.length===r||(0,A.a6)(s),++q){p=s[q]
B.c.a7(l,A.u([p.a.b,p.b],m))}o={}
o.a=l
o.b=n.b
o.c=n.c
o.d=n.e
o.e=!1
o.f=!1
o.g=n.d
return o}}
A.mT.prototype={
$1(a){if(a!=null)return A.ak(a)
return null},
$S:138}
A.or.prototype={
$1(a){return a},
$S:15}
A.os.prototype={
$1(a){return a==null?null:a},
$S:140}
A.fw.prototype={
aE(){return"MessageType."+this.b}}
A.oq.prototype={
dd(a,b){var s=A.aw(new A.a1(!1,null,null,"Unsupported request "+A.q(a.t)),null),r=new A.l($.o,t.e)
r.T(s)
return r},
ee(a,b){var s=A.aw(new A.a1(!1,null,null,"Unsupported request "+A.q(a.t)),null),r=new A.l($.o,t.e)
r.T(s)
return r},
aZ(a,b){var s=A.aw(new A.a1(!1,null,null,"Unsupported request "+A.q(a.t)),null),r=new A.l($.o,t.e)
r.T(s)
return r},
cs(a,b){var s=A.aw(new A.a1(!1,null,null,"Unsupported request "+A.q(a.t)),null),r=new A.l($.o,t.e)
r.T(s)
return r},
ct(a,b){var s=A.aw(new A.a1(!1,null,null,"Unsupported request "+A.q(a.t)),null),r=new A.l($.o,t.e)
r.T(s)
return r},
cr(a,b){var s=A.aw(new A.a1(!1,null,null,"Unsupported request "+A.q(a.t)),null),r=new A.l($.o,t.e)
r.T(s)
return r},
dg(a,b){var s=A.aw(new A.a1(!1,null,null,"Unsupported request "+A.q(a.t)),null),r=new A.l($.o,t.e)
r.T(s)
return r},
dc(a,b){var s=A.aw(new A.a1(!1,null,null,"Unsupported request "+A.q(a.t)),null),r=new A.l($.o,t.e)
r.T(s)
return r},
j7(a,b){var s=A.aw(new A.a1(!1,null,null,"Unsupported request "+A.q(a.t)),null),r=new A.l($.o,t.e)
r.T(s)
return r},
d9(a,b){var s=A.aw(new A.a1(!1,null,null,"Unsupported request "+A.q(a.t)),null),r=new A.l($.o,t.e)
r.T(s)
return r},
de(a,b){var s=A.aw(new A.a1(!1,null,null,"Unsupported request "+A.q(a.t)),null),r=new A.l($.o,t.e)
r.T(s)
return r},
dh(a,b){var s=A.aw(new A.a1(!1,null,null,"Unsupported request "+A.q(a.t)),null),r=new A.l($.o,t.e)
r.T(s)
return r},
df(a,b){var s=A.aw(new A.a1(!1,null,null,"Unsupported request "+A.q(a.t)),null),r=new A.l($.o,t.e)
r.T(s)
return r},
da(a,b){var s=A.aw(new A.a1(!1,null,null,"Unsupported request "+A.q(a.t)),null),r=new A.l($.o,t.e)
r.T(s)
return r},
j4(a,b){var s=A.aw(new A.a1(!1,null,null,"Unsupported request "+A.q(a.t)),null),r=new A.l($.o,t.e)
r.T(s)
return r},
j8(a,b){var s=A.aw(new A.a1(!1,null,null,"Unsupported request "+A.q(a.t)),null),r=new A.l($.o,t.e)
r.T(s)
return r},
j5(a,b){var s=A.aw(new A.a1(!1,null,null,"Unsupported request "+A.q(a.t)),null),r=new A.l($.o,t.e)
r.T(s)
return r},
n5(a,b){var s,r,q=this
switch(a.t){case"open":return q.dd(a,b)
case"connect":return q.ee(a,b)
case"custom":return q.aZ(a,b)
case"fileSystemExists":return q.cs(a,b)
case"fileSystemFlush":return q.ct(a,b)
case"fileSystemAccess":return q.cr(a,b)
case"runQuery":return q.dg(a,b)
case"exclusiveLock":return q.dc(a,b)
case"releaseLock":return q.j7(a,b)
case"closeDatabase":return q.d9(a,b)
case"openAdditionalConnection":return q.de(a,b)
case"updateRequest":return q.dh(a,b)
case"rollbackRequest":return q.df(a,b)
case"commitRequest":return q.da(a,b)
case"dedicatedCompatibilityCheck":return q.j4(a,b)
case"sharedCompatibilityCheck":return q.j8(a,b)
case"dedicatedInSharedCompatibilityCheck":return q.j5(a,b)
default:s=A.aw(new A.a1(!1,null,null,"Unsupported request "+A.q(a.t)),null)
r=new A.l($.o,t.e)
r.T(s)
return r}}}
A.cm.prototype={
aE(){return"FileSystemImplementation."+this.b}}
A.bu.prototype={
aE(){return"TypeCode."+this.b},
iV(a){var s,r=null,q=r
switch(this.a){case 0:q=A.r(A.H("Unsupported type code",r))
break
case 1:a=A.O(A.by(a))
q=a
break
case 2:q=t.bJ.a(a).toString()
s=A.BD(q,r)
if(s==null)A.r(A.ai("Could not parse BigInt",q,r))
q=s
break
case 3:A.by(a)
q=a
break
case 4:A.ak(a)
q=a
break
case 5:t.Z.a(a)
q=a
break
case 7:A.aX(a)
q=a
break
case 6:break}return q}}
A.cl.prototype={
iI(a){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c="binding parameter"
a.dL()
s=a.a
r=s.c
s=s.b
q=r.d
p=q.sqlite3_bind_parameter_count(s)
o=this.a
n=o.length
if(n!==p)throw A.c(A.H("Expected "+A.q(p)+" parameters, got "+A.q(n),null))
a.e=this
for(p=this.c,m=v.G,l=t.Z,k=t.bJ,j=0;j<n;j=g){i=p[j]
h=i>=8?B.w:B.I[i]
g=j+1
f=o[j]
switch(h.a){case 1:i=q.sqlite3_bind_int64(s,g,m.BigInt(A.O(A.by(f))))
if(i!==0)a.bv(i,c)
break
case 2:i=q.sqlite3_bind_int64(s,g,k.a(f))
if(i!==0)a.bv(i,c)
break
case 3:i=q.sqlite3_bind_double(s,g,A.by(f))
if(i!==0)a.bv(i,c)
break
case 4:e=B.o.av(A.ak(f))
i=q.dart_sqlite3_bind_text(s,g,r.fB(e),e.length)
if(i!==0)a.bv(i,c)
break
case 5:l.a(f)
i=q.dart_sqlite3_bind_blob(s,g,r.fB(f),f.length)
if(i!==0)a.bv(i,c)
break
case 6:i=q.sqlite3_bind_null(s,g)
if(i!==0)a.bv(i,c)
break
case 7:d=A.aX(f)?1:0
i=q.sqlite3_bind_int64(s,g,m.BigInt(d))
if(i!==0)a.bv(i,c)
break
case 0:throw A.c(A.R("Unknown type code"))}}},
gk(a){return this.a.length},
sk(a,b){this.iv()},
i(a,b){var s=this.c[b],r=s>=8?B.w:B.I[s]
return r.iV(this.a[b])},
m(a,b,c){this.iv()},
iv(){throw A.c(A.R("decodeValues list is unmodifiable"))}}
A.um.prototype={
$1(a){this.b.transaction.abort()
this.a.a=!1},
$S:14}
A.lK.prototype={
$1(a){this.a.U(this.c.a(this.b.result))},
$S:2}
A.lL.prototype={
$1(a){var s=this.b.error
if(s==null)s=a
this.a.a9(s)},
$S:2}
A.lO.prototype={
$1(a){this.a.U(this.c.a(this.b.result))},
$S:2}
A.lP.prototype={
$1(a){var s=this.b.error
if(s==null)s=a
this.a.a9(s)},
$S:2}
A.lQ.prototype={
$1(a){var s=this.b.error
if(s==null)s=a
this.a.a9(s)},
$S:2}
A.o4.prototype={
no(){var s,r,q,p
for(s=this.b,r=new A.b3(s,s.r,s.e);r.l();){q=r.d
if(!q.r){q.r=!0
if(!q.f){p=q.a
p.c.d.sqlite3_reset(p.b)
q.f=!0}q=q.a
p=q.c
p.d.sqlite3_finalize(q.b)
p=p.w
if(p!=null){p=p.a
if(p!=null)p.unregister(q.d)}}}s.aF(0)}}
A.fg.prototype={
aE(){return"FileType."+this.b}}
A.cy.prototype={
aE(){return"StorageMode."+this.b}}
A.d8.prototype={
j(a){return"Remote error: "+this.a},
$iJ:1}
A.bm.prototype={}
A.rn.prototype={
eL(){var s=v.G
if(!("Worker" in s))return null
return new A.rl(new s.Worker(this.a,{name:"sqlite3_worker"}))}}
A.tK.prototype={}
A.rl.prototype={}
A.tZ.prototype={
$1(a){return A.Q(a.data)},
$S:142}
A.hu.prototype={
u(){var s=this.a
if(s!=null)s.u()
this.a=null}}
A.ep.prototype={
n(){var s=0,r=A.i(t.H),q=this,p,o,n
var $async$n=A.d(function(a,b){if(a===1)return A.e(b,r)
for(;;)switch(s){case 0:q.c.u()
q.d.u()
q.e.u()
for(p=q.w,o=p.length,n=0;n<p.length;p.length===o||(0,A.a6)(p),++n)p[n].abort()
B.c.aF(p)
p=q.f
if(p!=null)p.b.L()
s=2
return A.b(q.a.d7(),$async$n)
case 2:return A.f(null,r)}})
return A.h($async$n,r)},
im(a){var s=new v.G.AbortController()
a.onabort=A.kH(new A.rd(s))
this.w.push(s)
return s},
ey(a,b,c,d){var s,r,q,p=this,o=null
if(a==null){s=p.a.f
if(!s.gmL()){r=p.im(b)
o=s.fW(c,r.signal,d).J(new A.rh(p,r))}}else{s=p.f
if((s==null?null:s.a)!==a)throw A.c(A.z("Requested operation on inactive lock state."))}if(o==null)o=A.dT(c,d)
q=p.a.z
return q instanceof A.cn?o.J(q.gnC()):o},
ol(a){var s=this,r=s.im(a),q=new A.l($.o,t.hy),p=new A.a9(q,t.ho),o=t.H
A.ir(s.a.f.fW(new A.re(s,p),r.signal,o),new A.rf(p),o,t.K)
return q.J(new A.rg(s,r))}}
A.rd.prototype={
$0(){return this.a.abort()},
$S:0}
A.rh.prototype={
$0(){B.c.H(this.a.w,this.b)},
$S:1}
A.re.prototype={
$0(){var s=this.a,r=s.r++,q=new A.l($.o,t.D)
s.f=new A.N(r,new A.a9(q,t.h))
this.b.U(r)
return q},
$S:3}
A.rf.prototype={
$2(a,b){var s=this.a
if((s.a.a&30)===0)s.b8(a,b)},
$S:7}
A.rg.prototype={
$0(){B.c.H(this.a.w,this.b)},
$S:1}
A.eo.prototype={
kO(a,b,c){this.b.a.J(new A.r1(this))},
cm(a,b){return this.lo(a,b)},
lo(a,b){var s=0,r=A.i(t.m),q,p=this
var $async$cm=A.d(function(c,d){if(c===1)return A.e(d,r)
for(;;)switch(s){case 0:s=3
return A.b(p.w.iO(a),$async$cm)
case 3:q={r:d.gjx(),i:a.i,t:"simpleSuccessResponse"}
s=1
break
case 1:return A.f(q,r)}})
return A.h($async$cm,r)},
j4(a,b){return this.cm(a,b)},
j5(a,b){return this.cm(a,b)},
j8(a,b){return this.cm(a,b)},
ee(a,b){return this.nH(a,b)},
nH(a,b){var s=0,r=A.i(t.m),q,p=this,o,n
var $async$ee=A.d(function(c,d){if(c===1)return A.e(d,r)
for(;;)switch(s){case 0:n=p.w.ghY()
n.toString
o={r:a.r,i:0,d:null,t:"connect"}
n.a.postMessage(o,A.dE(o))
q={r:null,i:a.i,t:"simpleSuccessResponse"}
s=1
break
case 1:return A.f(q,r)}})
return A.h($async$ee,r)},
aZ(a,b){return this.nJ(a,b)},
nJ(a,b){var s=0,r=A.i(t.m),q,p=this,o,n,m,l,k
var $async$aZ=A.d(function(c,d){if(c===1)return A.e(d,r)
for(;;)switch(s){case 0:k=a.d
s=k!=null?3:5
break
case 3:o=p.hI(k)
n=a.z
m=a.r
s=7
return A.b(o.a.gbu(),$async$aZ)
case 7:s=6
return A.b(d.cq(p,new A.m4(new A.r4(o,n,b),m)),$async$aZ)
case 6:l=d
s=4
break
case 5:s=8
return A.b(p.w.b.cq(p,new A.ia(a)),$async$aZ)
case 8:l=d
case 4:q={r:l,i:a.i,t:"simpleSuccessResponse"}
s=1
break
case 1:return A.f(q,r)}})
return A.h($async$aZ,r)},
dd(a,b){return this.nQ(a,b)},
nQ(a,b){var s=0,r=A.i(t.m),q,p=this
var $async$dd=A.d(function(c,d){if(c===1)return A.e(d,r)
for(;;)switch(s){case 0:s=3
return A.b(p.w.y.ha(new A.r7(p,a),t.m),$async$dd)
case 3:q=d
s=1
break
case 1:return A.f(q,r)}})
return A.h($async$dd,r)},
dg(a,b){return this.nU(a,b)},
nU(a,b){var s=0,r=A.i(t.m),q,p=this,o,n,m
var $async$dg=A.d(function(c,d){if(c===1)return A.e(d,r)
for(;;)switch(s){case 0:o=p.aW(a)
n=o.a
s=3
return A.b(n.gbu(),$async$dg)
case 3:m=d
q=o.ey(a.z,b,new A.ra(m,a,n),t.m)
s=1
break
case 1:return A.f(q,r)}})
return A.h($async$dg,r)},
dc(a,b){return this.nM(a,b)},
nM(a,b){var s=0,r=A.i(t.m),q,p=this
var $async$dc=A.d(function(c,d){if(c===1)return A.e(d,r)
for(;;)switch(s){case 0:s=3
return A.b(p.aW(a).ol(b),$async$dc)
case 3:q={r:d,i:a.i,t:"simpleSuccessResponse"}
s=1
break
case 1:return A.f(q,r)}})
return A.h($async$dc,r)},
j7(a,b){var s=this.aW(a),r=a.z,q=s.f
if((q==null?null:q.a)!==r)A.r(A.z("Lock to be released is not active."))
q.b.L()
s.f=null
return{r:null,i:a.i,t:"simpleSuccessResponse"}},
da(a,b){return this.nG(a,b)},
nG(a,b){var s=0,r=A.i(t.m),q,p=this,o,n
var $async$da=A.d(function(c,d){if(c===1)return A.e(d,r)
for(;;)switch(s){case 0:o=p.aW(a)
n=o.e
s=a.a?3:5
break
case 3:s=6
return A.b(p.cg(n,new A.r3(p,o),a),$async$da)
case 6:q=d
s=1
break
s=4
break
case 5:n.u()
q={r:null,i:a.i,t:"simpleSuccessResponse"}
s=1
break
case 4:case 1:return A.f(q,r)}})
return A.h($async$da,r)},
df(a,b){return this.nT(a,b)},
nT(a,b){var s=0,r=A.i(t.m),q,p=this,o,n
var $async$df=A.d(function(c,d){if(c===1)return A.e(d,r)
for(;;)switch(s){case 0:o=p.aW(a)
n=o.d
s=a.a?3:5
break
case 3:s=6
return A.b(p.cg(n,new A.r9(p,o),a),$async$df)
case 6:q=d
s=1
break
s=4
break
case 5:n.u()
q={r:null,i:a.i,t:"simpleSuccessResponse"}
s=1
break
case 4:case 1:return A.f(q,r)}})
return A.h($async$df,r)},
dh(a,b){return this.nV(a,b)},
nV(a,b){var s=0,r=A.i(t.m),q,p=this,o,n
var $async$dh=A.d(function(c,d){if(c===1)return A.e(d,r)
for(;;)switch(s){case 0:o=p.aW(a)
n=o.c
s=a.a?3:5
break
case 3:s=6
return A.b(p.cg(n,new A.rc(p,o),a),$async$dh)
case 6:q=d
s=1
break
s=4
break
case 5:n.u()
q={r:null,i:a.i,t:"simpleSuccessResponse"}
s=1
break
case 4:case 1:return A.f(q,r)}})
return A.h($async$dh,r)},
de(a,b){return this.nR(a,b)},
nR(a,b){var s=0,r=A.i(t.m),q,p=this,o,n,m
var $async$de=A.d(function(c,d){if(c===1)return A.e(d,r)
for(;;)switch(s){case 0:m=p.aW(a).a;++m.w
s=3
return A.b(A.un(),$async$de)
case 3:o=d
n=o.a
p.w.hq(o.b).x.push(A.xz(m,0))
q={r:n,i:a.i,t:"endpointResponse"}
s=1
break
case 1:return A.f(q,r)}})
return A.h($async$de,r)},
d9(a,b){return this.nF(a,b)},
nF(a,b){var s=0,r=A.i(t.m),q,p=this,o
var $async$d9=A.d(function(c,d){if(c===1)return A.e(d,r)
for(;;)switch(s){case 0:o=p.aW(a)
B.c.H(p.x,o)
s=3
return A.b(o.n(),$async$d9)
case 3:q={r:null,i:a.i,t:"simpleSuccessResponse"}
s=1
break
case 1:return A.f(q,r)}})
return A.h($async$d9,r)},
ct(a,b){return this.nP(a,b)},
nP(a,b){var s=0,r=A.i(t.m),q,p=this,o
var $async$ct=A.d(function(c,d){if(c===1)return A.e(d,r)
for(;;)switch(s){case 0:s=3
return A.b(p.aW(a).a.gbO(),$async$ct)
case 3:o=d
s=o instanceof A.cn?4:5
break
case 4:s=6
return A.b(o.j2(),$async$ct)
case 6:case 5:q={r:null,i:a.i,t:"simpleSuccessResponse"}
s=1
break
case 1:return A.f(q,r)}})
return A.h($async$ct,r)},
cr(a,b){return this.nN(a,b)},
nN(a,b){var s=0,r=A.i(t.m),q,p=this,o,n,m,l,k,j
var $async$cr=A.d(function(c,d){if(c===1)return A.e(d,r)
for(;;)switch(s){case 0:o=p.aW(a)
n=B.ad[a.f]
m=a.b
l=o
k=b
j=A
s=4
return A.b(o.a.gbO(),$async$cr)
case 4:s=3
return A.b(l.ey(null,k,new j.r5(d,n,m,a),t.m),$async$cr)
case 3:q=d
s=1
break
case 1:return A.f(q,r)}})
return A.h($async$cr,r)},
cs(a,b){return this.nO(a,b)},
nO(a,b){var s=0,r=A.i(t.m),q,p=this,o,n,m,l
var $async$cs=A.d(function(c,d){if(c===1)return A.e(d,r)
for(;;)switch(s){case 0:o=p.aW(a)
n=o
m=b
l=A
s=4
return A.b(o.a.gbO(),$async$cs)
case 4:s=3
return A.b(n.ey(null,m,new l.r6(d,a),t.y),$async$cs)
case 3:q={r:d,i:a.i,t:"simpleSuccessResponse"}
s=1
break
case 1:return A.f(q,r)}})
return A.h($async$cs,r)},
cg(a,b,c){return this.ko(a,b,c)},
ko(a,b,c){var s=0,r=A.i(t.m),q,p
var $async$cg=A.d(function(d,e){if(d===1)return A.e(e,r)
for(;;)switch(s){case 0:s=a.a==null?3:4
break
case 3:p=a
s=5
return A.b(b.$0(),$async$cg)
case 5:p.a=e
case 4:q={r:null,i:c.i,t:"simpleSuccessResponse"}
s=1
break
case 1:return A.f(q,r)}})
return A.h($async$cg,r)},
fK(a){},
aX(a){var s=0,r=A.i(t.X),q,p=this
var $async$aX=A.d(function(b,c){if(b===1)return A.e(c,r)
for(;;)switch(s){case 0:s=3
return A.b(p.ce({r:a,z:null,i:0,d:null,t:"custom"},B.q,t.m),$async$aX)
case 3:q=c.r
s=1
break
case 1:return A.f(q,r)}})
return A.h($async$aX,r)},
hI(a){return B.c.j1(this.x,new A.r0(a))},
aW(a){var s=a.d
if(s!=null)return this.hI(s)
else throw A.c(A.H("Request requires database id",null))},
$iwt:1}
A.r1.prototype={
$0(){var s=0,r=A.i(t.H),q=this,p,o,n
var $async$$0=A.d(function(a,b){if(a===1)return A.e(b,r)
for(;;)switch(s){case 0:p=q.a.x,o=p.length,n=0
case 2:if(!(n<p.length)){s=4
break}s=5
return A.b(p[n].n(),$async$$0)
case 5:case 3:p.length===o||(0,A.a6)(p),++n
s=2
break
case 4:B.c.aF(p)
return A.f(null,r)}})
return A.h($async$$0,r)},
$S:3}
A.r4.prototype={
$1$1(a,b){return this.a.ey(this.b,this.c,a,b)},
$1(a){return this.$1$1(a,t.z)},
$S:143}
A.r7.prototype={
$0(){var s=0,r=A.i(t.m),q,p=2,o=[],n=this,m,l,k,j,i,h,g
var $async$$0=A.d(function(a,b){if(a===1){o.push(b)
s=p}for(;;)switch(s){case 0:j=n.a
i=j.w
h=n.b
s=3
return A.b(i.br(h.u),$async$$0)
case 3:m=null
l=null
p=5
m=i.nB(h.d,A.Ad(h.s),h.c,h.a)
s=8
return A.b(h.o?m.gbO():m.gbu(),$async$$0)
case 8:l=A.xz(m,null)
j.x.push(l)
i={r:m.b,i:h.i,t:"simpleSuccessResponse"}
q=i
s=1
break
p=2
s=7
break
case 5:p=4
g=o.pop()
s=m!=null?9:10
break
case 9:B.c.H(j.x,l)
s=11
return A.b(m.d7(),$async$$0)
case 11:case 10:throw g
s=7
break
case 4:s=2
break
case 7:case 1:return A.f(q,r)
case 2:return A.e(o.at(-1),r)}})
return A.h($async$$0,r)},
$S:144}
A.ra.prototype={
$0(){var s,r,q,p,o=null,n="This database has already been closed",m=this.a.gd5(),l=this.b
if(l.c&&m.gd4())throw A.c(A.z("Database is not in a transaction"))
s=l.p
r=l.v
r.toString
q=new A.cl(s,r,A.aU(r,0,o))
s=this.c
if(l.r){p=s.ke(m,l.s,q)
p.i=l.i
p.x=m.gd4()
if(m.w)A.r(A.z(n))
l=m.b
p.y=A.O(v.G.Number(l.a.d.sqlite3_last_insert_rowid(l.b)))
return p}else{s.nu(m,l.s,q)
s=m.gd4()
if(m.w)A.r(A.z(n))
r=m.b
return A.yL(s,o,A.O(v.G.Number(r.a.d.sqlite3_last_insert_rowid(r.b))),l.i,o,o,o)}},
$S:18}
A.r3.prototype={
$0(){var s=0,r=A.i(t.ey),q,p=this,o
var $async$$0=A.d(function(a,b){if(a===1)return A.e(b,r)
for(;;)switch(s){case 0:o=p.b
s=3
return A.b(o.a.gbu(),$async$$0)
case 3:q=b.gd5().f_().gbA().O(new A.r2(p.a,o))
s=1
break
case 1:return A.f(q,r)}})
return A.h($async$$0,r)},
$S:31}
A.r2.prototype={
$1(a){var s={d:this.b.b,t:"notifyCommit"}
this.a.a.postMessage(s,A.dE(s))},
$S:22}
A.r9.prototype={
$0(){var s=0,r=A.i(t.ey),q,p=this,o
var $async$$0=A.d(function(a,b){if(a===1)return A.e(b,r)
for(;;)switch(s){case 0:o=p.b
s=3
return A.b(o.a.gbu(),$async$$0)
case 3:q=b.gd5().mb().gbA().O(new A.r8(p.a,o))
s=1
break
case 1:return A.f(q,r)}})
return A.h($async$$0,r)},
$S:31}
A.r8.prototype={
$1(a){var s={d:this.b.b,t:"notifyRollback"}
this.a.a.postMessage(s,A.dE(s))},
$S:22}
A.rc.prototype={
$0(){var s=0,r=A.i(t.ha),q,p=this,o
var $async$$0=A.d(function(a,b){if(a===1)return A.e(b,r)
for(;;)switch(s){case 0:o=p.b
s=3
return A.b(o.a.gbu(),$async$$0)
case 3:q=b.gd5().ix().gbA().O(new A.rb(p.a,o))
s=1
break
case 1:return A.f(q,r)}})
return A.h($async$$0,r)},
$S:147}
A.rb.prototype={
$1(a){var s={k:a.a.a,u:a.b,r:a.c,d:this.b.b,t:"notifyUpdate"}
this.a.a.postMessage(s,A.dE(s))},
$S:51}
A.r5.prototype={
$0(){var s,r,q,p=this,o=p.a.cd(new A.fH(A.ye(p.b)),4).a
try{q=p.c
if(q!=null){s=q
o.dv(s.byteLength)
o.cG(A.aU(s,0,null),0)
q={r:null,i:p.d.i,t:"simpleSuccessResponse"}
return q}else{q=o.cF()
r=new Uint8Array(q)
o.eG(r,0)
q={r:t.a.a(J.zD(r)),i:p.d.i,t:"simpleSuccessResponse"}
return q}}finally{o.eE()}},
$S:18}
A.r6.prototype={
$0(){return this.a.eD(A.ye(B.ad[this.b.f]),0)===1},
$S:52}
A.r0.prototype={
$1(a){return a.b===this.a},
$S:150}
A.id.prototype={
gbO(){var s=0,r=A.i(t.e6),q,p=this,o
var $async$gbO=A.d(function(a,b){if(a===1)return A.e(b,r)
for(;;)switch(s){case 0:o=p.y
s=3
return A.b(o==null?p.y=A.dT(new A.mM(p),t.H):o,$async$gbO)
case 3:o=p.z
o.toString
q=o
s=1
break
case 1:return A.f(q,r)}})
return A.h($async$gbO,r)},
gbu(){var s=0,r=A.i(t.u),q,p=this,o
var $async$gbu=A.d(function(a,b){if(a===1)return A.e(b,r)
for(;;)switch(s){case 0:o=p.x
s=3
return A.b(o==null?p.x=A.dT(new A.mL(p),t.u):o,$async$gbu)
case 3:q=b
s=1
break
case 1:return A.f(q,r)}})
return A.h($async$gbu,r)},
d7(){var s=0,r=A.i(t.H),q=this
var $async$d7=A.d(function(a,b){if(a===1)return A.e(b,r)
for(;;)switch(s){case 0:s=--q.w===0?2:3
break
case 2:s=4
return A.b(q.n(),$async$d7)
case 4:case 3:return A.f(null,r)}})
return A.h($async$d7,r)},
n(){var s=0,r=A.i(t.H),q=this,p,o,n,m,l,k,j
var $async$n=A.d(function(a,b){if(a===1)return A.e(b,r)
for(;;)switch(s){case 0:j=q.a.r
j.toString
s=2
return A.b(j,$async$n)
case 2:p=b
o=q.x
s=o!=null?3:4
break
case 3:s=5
return A.b(o,$async$n)
case 5:n=b
j=q.r
if(j!=null)j.no()
n.n()
m=q.z
if(m!=null){j=p.a
l=j.b
A.wB(m)
k=l.a.get(m)
if(k==null)A.r(A.z("vfs has not been registered"))
l.m(0,m,null)
j.a.d.dart_sqlite3_unregister_vfs(k)}case 4:j=q.Q
j=j==null?null:j.$0()
s=6
return A.b(j instanceof A.l?j:A.bL(j,t.H),$async$n)
case 6:q.f.js()
return A.f(null,r)}})
return A.h($async$n,r)},
i6(a,b){var s,r,q,p,o=this.r,n=o==null
if(n)s=null
else{r=o.b
q=r.H(0,b)
if(q!=null)r.m(0,b,q)
s=q}if(s!=null)return new A.N(s,!0)
p=a.jm(b,!0)
if(!n){p.dL()
n=p.a
n=n.c.d.sqlite3_stmt_isexplain(n.b)===0}else n=!1
if(n){n=o.b
if(n.a===o.a)n.H(0,new A.b2(n,A.p(n).h("b2<1>")).gai(0)).n()
n.m(0,p.d,p)
return new A.N(p,!0)}return new A.N(p,!1)},
nu(a,b,c){var s,r,q
if(c.gk(0)===0)return a.aY(b,B.n)
else{s=null
r=null
q=this.i6(a,b)
s=q.a
r=q.b
try{s.nw(new A.f9(c.giH()))}finally{if(r)s.dq()
else s.n()}}},
ke(a,b,c){var s,r=null,q=null,p=this.i6(a,b)
r=p.a
q=p.b
try{s=A.AV(r,c)
return s}finally{if(q)r.dq()
else r.n()}}}
A.mM.prototype={
$0(){var s=0,r=A.i(t.H),q=this,p,o,n,m,l,k
var $async$$0=A.d(function(a,b){if(a===1)return A.e(b,r)
for(;;)switch(s){case 0:l=q.a
k=l.d
case 2:switch(k.a){case 0:s=4
break
case 1:s=5
break
case 2:s=6
break
case 3:s=7
break
case 4:s=8
break
default:s=3
break}break
case 4:s=9
return A.b(A.ow("drift_db/"+l.c,"vfs-web-"+l.b),$async$$0)
case 9:p=b
l.z=p
l.Q=p.gaG()
s=3
break
case 5:case 6:s=10
return A.b(A.ip("drift_db/"+l.c,k===B.H,"vfs-web-"+l.b),$async$$0)
case 10:o=b
l.f.f=o
n=o.a
l.z=n
l.Q=n.gaG()
s=3
break
case 7:s=11
return A.b(A.iu(l.c,"vfs-web-"+l.b,!1),$async$$0)
case 11:m=b
l.z=m
l.Q=m.gaG()
s=3
break
case 8:l.z=A.vb("vfs-web-"+l.b,null)
s=3
break
case 3:return A.f(null,r)}})
return A.h($async$$0,r)},
$S:3}
A.mL.prototype={
$0(){var s=0,r=A.i(t.u),q,p=this,o,n,m,l,k,j
var $async$$0=A.d(function(a,b){if(a===1)return A.e(b,r)
for(;;)switch(s){case 0:k=p.a
j=k.a.r
j.toString
s=3
return A.b(j,$async$$0)
case 3:o=b
s=4
return A.b(k.gbO(),$async$$0)
case 4:n=b
o.ja()
j=o.a
m=j.b
A.wB(n)
if(m.a.get(n)!=null)A.r(A.z("vfs has already been registered"))
j=j.a
l=j.d.dart_sqlite3_register_vfs(j.d3(B.o.av(n.a),1),n,0)
if(l===0)A.r(A.z("could not register vfs"))
m.m(0,n,l)
s=5
return A.b(k.f.fW(new A.mK(k,o),null,t.u),$async$$0)
case 5:q=b
s=1
break
case 1:return A.f(q,r)}})
return A.h($async$$0,r)},
$S:53}
A.mK.prototype={
$0(){var s=this.a
return s.a.b.h_(this.b,"/database","vfs-web-"+s.b,s.e)},
$S:53}
A.ql.prototype={
ghY(){var s,r=this,q=r.Q
if(q===$){s=r.a.gmQ().eL()
r.Q!==$&&A.w9()
r.Q=s
q=s}return q},
cu(){var s=0,r=A.i(t.H),q=1,p=[],o=[],n=this,m,l,k,j,i,h
var $async$cu=A.d(function(a,b){if(a===1){p.push(b)
s=q}for(;;)switch(s){case 0:h=new A.bO(A.bA(A.CL(n.a),"stream",t.K))
q=2
j=v.G
case 5:s=7
return A.b(h.l(),$async$cu)
case 7:if(!b){s=6
break}m=h.gp()
s=J.A(m.t,"connect")?8:10
break
case 8:i=m.r
l=new A.dN(i.port,i.lockName,null)
n.hq(l)
s=9
break
case 10:s=A.E8(m.t)?11:12
break
case 11:s=13
return A.b(n.iO(m),$async$cu)
case 13:k=b
j.postMessage(k.gjx())
case 12:case 9:s=5
break
case 6:o.push(4)
s=3
break
case 2:o=[1]
case 3:q=1
s=14
return A.b(h.u(),$async$cu)
case 14:s=o.pop()
break
case 4:return A.f(null,r)
case 1:return A.e(p.at(-1),r)}})
return A.h($async$cu,r)},
hq(a){var s=this,r=A.BG(a,s.d++,s)
s.c.push(r)
r.b.a.J(new A.qm(s,r))
return r},
iO(a){return this.x.ha(new A.qn(this,a),t.p6)},
br(a){return this.o9(a)},
o9(a){var s=0,r=A.i(t.H),q=this,p,o,n,m
var $async$br=A.d(function(b,c){if(b===1)return A.e(c,r)
for(;;)switch(s){case 0:n=v.G
m=new n.URL(a,A.Q(n.location).href).href
n=q.r
s=n!=null?2:4
break
case 2:p=q.w
if(p!==m)throw A.c(A.z("Workers only support a single sqlite3 wasm module, provided different URI (has "+A.q(p)+", got "+m+")"))
s=5
return A.b(t.jN.b(n)?n:A.bL(n,t.he),$async$br)
case 5:s=3
break
case 4:o=A.ir(q.b.br(m),new A.qo(q),t.w,t.K)
q.r=o
s=6
return A.b(o,$async$br)
case 6:q.w=m
case 3:return A.f(null,r)}})
return A.h($async$br,r)},
nB(a,b,c,d){var s,r,q,p,o,n
for(s=this.e,r=new A.b3(s,s.r,s.e);r.l();){q=r.d
p=q.w
if(p!==0&&q.c===a&&q.d===b){q.w=p+1
return q}}r=this.f++
q="pkg-sqlite3-web-"+a
p=b===B.H||b===B.a7
o=A.nL(t.cj)
n=c===0?null:new A.o4(c,A.vi(null,null,t.N,t.fw))
n=new A.id(this,r,a,b,d,new A.ic(q+"-outer",q,q+"-tmp",new A.dZ(o),p),n)
s.m(0,r,n)
return n}}
A.qm.prototype={
$0(){var s=this.a,r=s.c
B.c.H(r,this.b)
if(r.length===0)s.a.n()
return null},
$S:0}
A.qn.prototype={
$0(){var s=0,r=A.i(t.p6),q,p=this,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a
var $async$$0=A.d(function(a0,a1){if(a0===1)return A.e(a1,r)
for(;;)switch(s){case 0:d=p.b
c=d.d
s=J.A(d.t,"dedicatedCompatibilityCheck")||J.A(d.t,"dedicatedInSharedCompatibilityCheck")?3:5
break
case 3:s=6
return A.b(A.cK(),$async$$0)
case 6:o=a1
n=o.a
m=o.b
l=m
k=n
s=4
break
case 5:k=!1
l=!1
case 4:b=J.A(d.t,"dedicatedCompatibilityCheck")||J.A(d.t,"sharedCompatibilityCheck")
if(b){s=7
break}else a1=b
s=8
break
case 7:s=9
return A.b(A.kM(),$async$$0)
case 9:case 8:j=a1
i=A.bp(t.cU)
s=J.A(d.t,"sharedCompatibilityCheck")?10:12
break
case 10:h=p.a.ghY()
g=h!=null
s=g?13:14
break
case 13:d={d:c,i:0,t:"dedicatedInSharedCompatibilityCheck"}
f=A.dE(d)
n=h.a
n.postMessage(d,f)
b=A
a=A
s=15
return A.b(new A.eu(n,"message",!1,t.d4).gai(0),$async$$0)
case 15:e=b.zW(a.Q(a1.data))
k=e.c
l=e.d
i.a7(0,e.a)
case 14:s=11
break
case 12:g=!1
case 11:s=k?16:17
break
case 16:b=J
s=18
return A.b(A.eV(),$async$$0)
case 18:d=b.a0(a1)
case 19:if(!d.l()){s=20
break}i.q(0,new A.N(B.am,d.gp()))
s=19
break
case 20:case 17:s=j&&c!=null?21:22
break
case 21:s=23
return A.b(A.ul(c),$async$$0)
case 23:if(a1)i.q(0,new A.N(B.an,c))
case 22:d=A.an(i,i.$ti.c)
q=new A.cW(d,g,k,l,j)
s=1
break
case 1:return A.f(q,r)}})
return A.h($async$$0,r)},
$S:152}
A.qo.prototype={
$2(a,b){this.a.r=null
throw A.c(a)},
$S:153}
A.iH.prototype={
j(a){return"LockError: "+this.a}}
A.tf.prototype={
bJ(a,b,c){return this.od(a,b,c,c)},
od(a,b,c,d){var s=0,r=A.i(d),q,p=this,o,n,m
var $async$bJ=A.d(function(e,f){if(e===1)return A.e(f,r)
for(;;)switch(s){case 0:if($.o.i(0,p)!=null)throw A.c(new A.iH("Recursive lock is not allowed"))
o=$.o
n=t.X
m=o.hQ(o,null,A.bD([p,!0],n,n))
q=m.c2(m,new A.tk(p,b,a,c),c.h("0/"))
s=1
break
case 1:return A.f(q,r)}})
return A.h($async$bJ,r)}}
A.tg.prototype={
$1(a){},
$S:12}
A.tk.prototype={
$0(){return this.k0(this.d)},
k0(a){var s=0,r=A.i(a),q,p=2,o=[],n=[],m=this,l,k,j,i,h,g,f,e,d,c
var $async$$0=A.d(function(b,a0){if(b===1){o.push(a0)
s=p}for(;;)switch(s){case 0:j={}
i=m.a
h=i.a
g=j.a=!1
f=$.o
e=t.D
d=t.F
c=new A.L(new A.l(f,e),d)
i.a=c.a
p=3
s=h!=null?6:7
break
case 6:l=new A.L(new A.l(f,e),d)
h.aK(new A.th(j,l),t.P)
f=m.b
if(f!=null)f.J(new A.ti(l))
s=8
return A.b(l.a,$async$$0)
case 8:case 7:s=9
return A.b(m.c.$0(),$async$$0)
case 9:f=a0
q=f
n=[1]
s=4
break
n.push(5)
s=4
break
case 3:n=[2]
case 4:p=2
k=new A.tl(i,c)
if(h!=null?!j.a:g)h.aK(new A.tj(k),t.P).lu()
else k.$0()
s=n.pop()
break
case 5:case 1:return A.f(q,r)
case 2:return A.e(o.at(-1),r)}})
return A.h($async$$0,r)},
$S(){return this.d.h("n<0>()")}}
A.th.prototype={
$1(a){var s
this.a.a=!0
s=this.b
if((s.a.a&30)===0)s.L()},
$S:9}
A.ti.prototype={
$0(){var s=this.a
if((s.a.a&30)===0)s.b8(new A.bB("lock"),A.ec())},
$S:1}
A.tl.prototype={
$0(){var s=this.a,r=this.b
if(s.a===r.a)s.a=null
r.L()},
$S:0}
A.tj.prototype={
$1(a){this.a.$0()},
$S:9}
A.jf.prototype={}
A.jg.prototype={
ow(a,b){return this.jq(new A.oD(this,a,b),"readTransaction()",null,b)}}
A.oD.prototype={
$1(a){return this.jP(a,this.c)},
jP(a,b){var s=0,r=A.i(b),q,p=this
var $async$$1=A.d(function(c,d){if(c===1)return A.e(d,r)
for(;;)switch(s){case 0:s=3
return A.b(A.eT(a,p.b,!1,p.c),$async$$1)
case 3:q=d
s=1
break
case 1:return A.f(q,r)}})
return A.h($async$$1,r)},
$S(){return this.c.h("n<0>(aA)")}}
A.bB.prototype={
j(a){return"A call to "+this.a+" has been aborted"},
$iJ:1}
A.jv.prototype={
bw(a,b){return this.k6(a,b)},
k6(a,b){var s=0,r=A.i(t.oy),q,p=this,o
var $async$bw=A.d(function(c,d){if(c===1)return A.e(d,r)
for(;;)switch(s){case 0:s=3
return A.b(p.aC(a,b),$async$bw)
case 3:o=d
q=o.gai(o)
s=1
break
case 1:return A.f(q,r)}})
return A.h($async$bw,r)},
aR(a,b){return this.ka(a,b)},
ka(a,b){var s=0,r=A.i(t.x),q,p=this,o
var $async$aR=A.d(function(c,d){if(c===1)return A.e(d,r)
for(;;)switch(s){case 0:o=A
s=3
return A.b(p.aC(a,b),$async$aR)
case 3:q=o.An(d)
s=1
break
case 1:return A.f(q,r)}})
return A.h($async$aR,r)},
e7(){var s=0,r=A.i(t.H),q=this
var $async$e7=A.d(function(a,b){if(a===1)return A.e(b,r)
for(;;)switch(s){case 0:s=2
return A.b(q.bx(),$async$e7)
case 2:if(!b)throw A.c(A.jh(null,null,0,"Dangling transaction detected. If you want to use BEGIN statements manually, COMMIT or ROLLBACK them before returning from writeLock.",null,null,null))
return A.f(null,r)}})
return A.h($async$e7,r)},
$iaA:1}
A.fE.prototype={
cP(){if(this.c)A.r(A.z("This context to a callback is no longer open. Make sure to await all statements on a database to avoid a context still being used after its callback has finished."))
if(this.b)throw A.c(A.z("The context from the callback was locked, e.g. due to a nested transaction."))},
bw(a,b){return this.k5(a,b)},
k5(a,b){var s=0,r=A.i(t.oy),q,p=this
var $async$bw=A.d(function(c,d){if(c===1)return A.e(d,r)
for(;;)switch(s){case 0:p.cP()
q=p.a.bw(a,b)
s=1
break
case 1:return A.f(q,r)}})
return A.h($async$bw,r)},
aC(a,b){return this.k7(a,b)},
eI(a){return this.aC(a,B.n)},
k7(a,b){var s=0,r=A.i(t.G),q,p=this
var $async$aC=A.d(function(c,d){if(c===1)return A.e(d,r)
for(;;)switch(s){case 0:p.cP()
s=3
return A.b(p.a.aC(a,b),$async$aC)
case 3:q=d
s=1
break
case 1:return A.f(q,r)}})
return A.h($async$aC,r)},
aR(a,b){return this.k9(a,b)},
dA(a){return this.aR(a,B.n)},
k9(a,b){var s=0,r=A.i(t.x),q,p=this
var $async$aR=A.d(function(c,d){if(c===1)return A.e(d,r)
for(;;)switch(s){case 0:p.cP()
q=p.a.aR(a,b)
s=1
break
case 1:return A.f(q,r)}})
return A.h($async$aR,r)},
$iaA:1}
A.fF.prototype={
aY(a,b){return this.nv(a,b)},
iX(a){return this.aY(a,B.n)},
nv(a,b){var s=0,r=A.i(t.G),q,p=this
var $async$aY=A.d(function(c,d){if(c===1)return A.e(d,r)
for(;;)switch(s){case 0:p.cP()
s=3
return A.b(p.a.aY(a,b),$async$aY)
case 3:q=d
s=1
break
case 1:return A.f(q,r)}})
return A.h($async$aY,r)},
b_(a,b){return this.oW(a,b,b)},
oW(a2,a3,a4){var s=0,r=A.i(a4),q,p=2,o=[],n=[],m=this,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1
var $async$b_=A.d(function(a5,a6){if(a5===1){o.push(a6)
s=p}for(;;)switch(s){case 0:m.cP()
l=null
k=null
j=null
f=m.d
e=A.AZ(f)
l=e.a
k=e.b
j=e.c
i=null
d=m.a
if(f===0){c=new A.ce(d.a,d.b,null)
c.d=!0}else c=d
h=c
p=4
m.b=!0
s=7
return A.b(d.aY(l,B.n),$async$b_)
case 7:i=new A.fF(f+1,h)
s=8
return A.b(a2.$1(i),$async$b_)
case 8:g=a6
s=9
return A.b(h.aY(k,B.n),$async$b_)
case 9:q=g
n=[1]
s=5
break
n.push(6)
s=5
break
case 4:p=3
a0=o.pop()
p=11
s=14
return A.b(h.aY(j,B.n),$async$b_)
case 14:p=3
s=13
break
case 11:p=10
a1=o.pop()
s=13
break
case 10:s=3
break
case 13:throw a0
n.push(6)
s=5
break
case 3:n=[2]
case 5:p=2
m.b=!1
f=i
if(f!=null)f.c=!0
s=n.pop()
break
case 6:case 1:return A.f(q,r)
case 2:return A.e(o.at(-1),r)}})
return A.h($async$b_,r)},
$iaJ:1}
A.je.prototype={
jq(a,b,c,d){return this.mA(a,null,b,d)},
jp(a,b,c){return this.jq(a,b,null,c)},
aC(a,b){return this.jp(new A.oB(a,b),"getAll()",t.G)},
aR(a,b){return this.jp(new A.oC(a,b),"getOptional()",t.x)},
dA(a){return this.aR(a,B.n)},
$iaA:1,
$iaJ:1}
A.oB.prototype={
$1(a){return this.jN(a)},
jN(a){var s=0,r=A.i(t.G),q,p=this
var $async$$1=A.d(function(b,c){if(b===1)return A.e(c,r)
for(;;)switch(s){case 0:q=a.aC(p.a,p.b)
s=1
break
case 1:return A.f(q,r)}})
return A.h($async$$1,r)},
$S:154}
A.oC.prototype={
$1(a){return this.jO(a)},
jO(a){var s=0,r=A.i(t.x),q,p=this
var $async$$1=A.d(function(b,c){if(b===1)return A.e(c,r)
for(;;)switch(s){case 0:q=a.aR(p.a,p.b)
s=1
break
case 1:return A.f(q,r)}})
return A.h($async$$1,r)},
$S:155}
A.I.prototype={
D(a,b){if(b==null)return!1
return b instanceof A.I&&B.b_.bG(b.a,this.a)},
gv(a){return A.AH(this.a)},
j(a){return"UpdateNotification<"+this.a.j(0)+">"},
cE(a){return new A.I(this.a.cE(a.a))},
fD(a){var s
for(s=this.a,s=s.gA(s);s.l();)if(a.V(0,s.gp().toLowerCase()))return!0
return!1}}
A.pH.prototype={
$2(a,b){return a.cE(b)},
$S:156}
A.pG.prototype={
$1(a){return new A.cf(new A.pF(this.a),a,A.p(a).h("cf<C.T>"))},
$S:157}
A.pF.prototype={
$1(a){return a.fD(this.a)},
$S:158}
A.ub.prototype={
$1(a){var s,r,q,p,o=this,n={}
n.a=n.b=null
n.c=!1
s=new A.uc(n,a)
r=A.xy()
q=new A.ud(n,a,s,r)
r.b=new A.u7(n,o.a,q)
p=o.c.az(new A.ue(n,o.b,q,o.f),new A.uf(s,a),new A.ug(s,a))
a.e=new A.u8(n)
a.f=new A.u9(n,r,q)
a.r=new A.ua(n,p)
a.q(0,o.d)
r.dQ().$0()},
$S(){return this.f.h("~(bZ<0>)")}}
A.uc.prototype={
$0(){var s,r=this.a,q=r.b
if(q!=null){r.b=null
this.b.mI(q)
s=r.a
if(s!=null)s.u()
r.a=null
return!0}else return!1},
$S:52}
A.ud.prototype={
$0(){var s,r,q=this,p=q.a
if(p.a==null){s=q.b
r=s.b
s=!((r&1)!==0?(s.ga6().e&4)!==0:(r&2)===0)}else s=!1
if(s)if(q.c.$0()){s=q.b
r=s.b
if((r&1)!==0?(s.ga6().e&4)!==0:(r&2)===0)p.c=!0
else q.d.dQ().$0()}},
$S:0}
A.u7.prototype={
$0(){var s=this.a
s.a=A.jq(this.b,new A.u6(s,this.c))},
$S:0}
A.u6.prototype={
$0(){this.a.a=null
this.b.$0()},
$S:0}
A.ue.prototype={
$1(a){var s,r=this.a,q=r.b
A:{if(q==null){s=a
break A}s=this.b.$2(q,a)
break A}r.b=s
this.c.$0()},
$S(){return this.d.h("~(0)")}}
A.ug.prototype={
$2(a,b){this.a.$0()
this.b.mF(a,b)},
$S:6}
A.uf.prototype={
$0(){this.a.$0()
this.b.iP()},
$S:0}
A.u8.prototype={
$0(){var s=this.a,r=s.a,q=r==null
s.c=!q
if(!q)r.u()
s.a=null},
$S:0}
A.u9.prototype={
$0(){if(this.a.c)this.b.dQ().$0()
else this.c.$0()},
$S:0}
A.ua.prototype={
$0(){var s=0,r=A.i(t.H),q,p=this,o
var $async$$0=A.d(function(a,b){if(a===1)return A.e(b,r)
for(;;)switch(s){case 0:o=p.a.a
if(o!=null)o.u()
q=p.b.u()
s=1
break
case 1:return A.f(q,r)}})
return A.h($async$$0,r)},
$S:3}
A.pw.prototype={
$0(){this.a.pJ()},
$S:1}
A.pu.prototype={
$1(a){this.a.q(0,a.b)},
$S:51}
A.pr.prototype={
$0(){var s,r,q,p,o,n,m,l,k,j,i
for(s=this.a,r=s.length,q=this.b,p=t.N,o=0;o<s.length;s.length===r||(0,A.a6)(s),++o){n=s[o]
n.b.a7(0,q)
m=n.a
l=m.b
k=(l&1)!==0
if(!(k?(m.ga6().e&4)!==0:(l&2)===0)){j=n.b
if(j.a!==0){if(l>=4)A.r(m.aq())
if(k)m.a2(j)
else if((l&3)===0){m=m.bV()
j=new A.bv(j)
i=m.c
if(i==null)m.b=m.c=j
else{i.sbs(j)
m.c=j}}n.b=A.bp(p)}}}q.aF(0)},
$S:0}
A.ps.prototype={
$0(){this.a.aF(0)},
$S:0}
A.po.prototype={
$1(a){var s,r,q=this,p=q.b
p.push(a)
if(p.length===1){p=q.c
s=p.ix()
r=s.w
s=r==null?s.w=s.hS(!0):r
q.a.a=A.u([s.O(q.d),p.f_().gbA().O(new A.pp(q.e)),p.f_().gbA().O(new A.pq(q.f))],t.bO)}},
$S:54}
A.pp.prototype={
$1(a){return this.a.$0()},
$S:22}
A.pq.prototype={
$1(a){return this.a.$0()},
$S:22}
A.pv.prototype={
$1(a){var s,r,q=this.b
B.c.H(q,a)
if(q.length===0)for(q=this.a.a,s=q.length,r=0;r<q.length;q.length===s||(0,A.a6)(q),++r)q[r].u()},
$S:54}
A.pt.prototype={
$1(a){var s=new A.dx(a,A.bp(t.N))
this.a.$1(s)
a.f=s.gmG()
a.r=new A.pn(this.b,s)},
$S:160}
A.pn.prototype={
$0(){return this.a.$1(this.b)},
$S:0}
A.dx.prototype={
mH(){var s=this.b
if(s.a!==0){this.a.q(0,s)
this.b=A.bp(t.N)}}}
A.jC.prototype={
bx(){var s=0,r=A.i(t.y),q,p=this,o,n
var $async$bx=A.d(function(a,b){if(a===1)return A.e(b,r)
for(;;)switch(s){case 0:n=A
s=3
return A.b(p.a.aX({rawKind:"getAutoCommit"}),$async$bx)
case 3:o=n.vN(b)
if(o==null)o=null
q=o===!0
s=1
break
case 1:return A.f(q,r)}})
return A.h($async$bx,r)},
mA(a,b,c,d){return this.bY(new A.q2(a,d),b,c,d)},
b_(a,b){return this.lC(new A.q5(a,b),null,b)},
e0(a,b,c,d){return this.mC(a,b,c,d,d)},
mB(a,b,c){return this.e0(a,b,null,c)},
mC(a,b,c,d,e){var s=0,r=A.i(e),q,p=this
var $async$e0=A.d(function(f,g){if(f===1)return A.e(g,r)
for(;;)switch(s){case 0:s=3
return A.b(p.bY(new A.q3(a,d),b,c,d),$async$e0)
case 3:q=g
s=1
break
case 1:return A.f(q,r)}})
return A.h($async$e0,r)},
bY(a,b,c,d){return this.lD(a,b,c,d,d)},
lC(a,b,c){return this.bY(a,b,null,c)},
lD(a,b,c,d,e){var s=0,r=A.i(e),q,p=this,o,n
var $async$bY=A.d(function(f,g){if(f===1)return A.e(g,r)
for(;;)switch(s){case 0:n=p.b
s=n!=null?3:5
break
case 3:s=6
return A.b(n.bJ(new A.q0(p,a,d),b,d),$async$bY)
case 6:q=g
s=1
break
s=4
break
case 5:o=p.a.cC(new A.q1(p,a,d),b,d)
s=7
return A.b(A.CM(o,c==null?"lock":c,d),$async$bY)
case 7:q=g
s=1
break
case 4:case 1:return A.f(q,r)}})
return A.h($async$bY,r)},
$ivu:1}
A.q2.prototype={
$1(a){return A.ot(a,this.a,this.b)},
$S(){return this.b.h("n<0>(ce)")}}
A.q5.prototype={
$1(a){var s=this.b
return A.fG(a,new A.q4(this.a,s),s)},
$S(){return this.b.h("n<0>(ce)")}}
A.q4.prototype={
$1(a){return this.jV(a,this.b)},
jV(a,b){var s=0,r=A.i(b),q,p=this
var $async$$1=A.d(function(c,d){if(c===1)return A.e(d,r)
for(;;)switch(s){case 0:s=3
return A.b(a.b_(p.a,p.b),$async$$1)
case 3:q=d
s=1
break
case 1:return A.f(q,r)}})
return A.h($async$$1,r)},
$S(){return this.b.h("n<0>(aJ)")}}
A.q3.prototype={
$1(a){return A.fG(a,this.a,this.b)},
$S(){return this.b.h("n<0>(ce)")}}
A.q0.prototype={
$0(){return this.jU(this.c)},
jU(a){var s=0,r=A.i(a),q,p=this
var $async$$0=A.d(function(b,c){if(b===1)return A.e(c,r)
for(;;)switch(s){case 0:s=3
return A.b(p.b.$1(new A.ce(p.a,null,null)),$async$$0)
case 3:q=c
s=1
break
case 1:return A.f(q,r)}})
return A.h($async$$0,r)},
$S(){return this.c.h("n<0>()")}}
A.q1.prototype={
$1(a){return this.jT(a,this.c)},
jT(a,b){var s=0,r=A.i(b),q,p=this
var $async$$1=A.d(function(c,d){if(c===1)return A.e(d,r)
for(;;)switch(s){case 0:s=3
return A.b(p.b.$1(new A.ce(p.a,a,null)),$async$$1)
case 3:q=d
s=1
break
case 1:return A.f(q,r)}})
return A.h($async$$1,r)},
$S(){return this.c.h("n<0>(a)")}}
A.ce.prototype={
aC(a,b){return this.k8(a,b)},
k8(a,b){var s=0,r=A.i(t.G),q,p=this
var $async$aC=A.d(function(c,d){if(c===1)return A.e(d,r)
for(;;)switch(s){case 0:q=A.xj(p.c,"getAll",new A.tE(p,a,b),b,a,t.G)
s=1
break
case 1:return A.f(q,r)}})
return A.h($async$aC,r)},
bx(){var s=0,r=A.i(t.y),q,p=this
var $async$bx=A.d(function(a,b){if(a===1)return A.e(b,r)
for(;;)switch(s){case 0:q=p.a.bx()
s=1
break
case 1:return A.f(q,r)}})
return A.h($async$bx,r)},
aY(a,b){return A.xj(this.c,"execute",new A.tC(this,a,b),b,a,t.G)}}
A.tE.prototype={
$0(){var s=0,r=A.i(t.G),q,p=this
var $async$$0=A.d(function(a,b){if(a===1)return A.e(b,r)
for(;;)switch(s){case 0:s=3
return A.b(A.kR(new A.tD(p.a,p.b,p.c),t.G),$async$$0)
case 3:q=b
s=1
break
case 1:return A.f(q,r)}})
return A.h($async$$0,r)},
$S:16}
A.tD.prototype={
$0(){var s=0,r=A.i(t.G),q,p=this,o
var $async$$0=A.d(function(a,b){if(a===1)return A.e(b,r)
for(;;)switch(s){case 0:o=p.a
s=3
return A.b(o.a.a.cI(p.b,o.d,p.c,o.b),$async$$0)
case 3:q=b.c
s=1
break
case 1:return A.f(q,r)}})
return A.h($async$$0,r)},
$S:16}
A.tC.prototype={
$0(){return A.kR(new A.tB(this.a,this.b,this.c),t.G)},
$S:16}
A.tB.prototype={
$0(){var s=0,r=A.i(t.G),q,p=this,o
var $async$$0=A.d(function(a,b){if(a===1)return A.e(b,r)
for(;;)switch(s){case 0:o=p.a
s=3
return A.b(o.a.a.cI(p.b,o.d,p.c,o.b),$async$$0)
case 3:q=b.c
s=1
break
case 1:return A.f(q,r)}})
return A.h($async$$0,r)},
$S:16}
A.u_.prototype={
$2(a,b){return A.ik(new A.bB(this.a),b)},
$S:162}
A.i1.prototype={
goL(){var s=t.d4,r=s.h("aL<C.T,I?>"),q=r.h("cf<C.T>")
return new A.cT(new A.cf(new A.li(),new A.aL(new A.lj(),new A.eu(this.b,"message",!1,s),r),q),q.h("cT<C.T,I>"))},
ap(a){this.b.postMessage(A.BE(a))}}
A.lj.prototype={
$1(a){var s,r,q=A.Q(a.data)
if(J.A(q.a,0)){s=t.c.a(q.b)
r=t.k.b(s)?s:new A.ae(s,A.a5(s).h("ae<1,j>"))
return new A.I(J.dI(r,new A.lh(),t.N).du(0))}else return null},
$S:164}
A.lh.prototype={
$1(a){return a},
$S:15}
A.li.prototype={
$1(a){return a!=null},
$S:165}
A.qV.prototype={
$1(a){return a},
$S:15}
A.bR.prototype={
aE(){return"CustomDatabaseMessageKind."+this.b}}
A.jw.prototype={
fL(a){var s=0,r=A.i(t.X),q,p=this,o,n
var $async$fL=A.d(function(b,c){if(b===1)return A.e(c,r)
for(;;)switch(s){case 0:A.Q(a)
if(A.mS(B.ae,a.rawKind)===B.F){o=a.rawParameters
o=B.c.ba(o,new A.pC(),t.N).du(0)
n=p.b.i(0,a.rawSql)
if(n!=null)n.q(0,new A.I(o))}q=null
s=1
break
case 1:return A.f(q,r)}})
return A.h($async$fL,r)},
oM(a){var s=null,r=B.b.j(this.a++),q=A.bH(s,s,s,s,!1,t.d)
this.b.m(0,r,q)
q.d=new A.pD(a,r)
q.r=new A.pE(this,a,r)
return new A.a4(q,A.p(q).h("a4<1>"))}}
A.pC.prototype={
$1(a){return A.ak(a)},
$S:43}
A.pD.prototype={
$0(){this.a.aX(A.v6(B.E,this.b,[!0]))},
$S:0}
A.pE.prototype={
$0(){var s=this.c
this.b.aX(A.v6(B.E,s,[!1]))
this.a.b.H(0,s)},
$S:1}
A.q8.prototype={
bJ(a,b,c){if("locks" in v.G.navigator)return this.d2(a,b,c)
else return this.a.bJ(a,b,c)},
oc(a,b){return this.bJ(a,null,b)},
d2(a,b,c){return this.mt(a,b,c,c)},
mt(a,b,c,d){var s=0,r=A.i(d),q,p=2,o=[],n=[],m=this,l,k
var $async$d2=A.d(function(e,f){if(e===1){o.push(f)
s=p}for(;;)switch(s){case 0:s=3
return A.b(m.ln(b),$async$d2)
case 3:k=f
p=4
s=7
return A.b(a.$0(),$async$d2)
case 7:l=f
q=l
n=[1]
s=5
break
n.push(6)
s=5
break
case 4:n=[2]
case 5:p=2
k.a.L()
s=n.pop()
break
case 6:case 1:return A.f(q,r)
case 2:return A.e(o.at(-1),r)}})
return A.h($async$d2,r)},
ln(a){var s,r=new A.l($.o,t.nI),q=new A.L(r,t.aP),p=v.G,o=new p.AbortController()
if(a!=null)a.J(new A.qa(this,q,o))
s={}
s.signal=o.signal
A.aq(p.navigator.locks.request(this.b,s,A.bz(new A.qc(q))),t.X).iN(new A.qb())
return r}}
A.qa.prototype={
$0(){var s=this.b
if((s.a.a&30)===0){s.a9(new A.bB("getWebLock("+this.a.b+")"))
this.c.abort("aborted in Dart")}},
$S:1}
A.qc.prototype={
$1(a){var s=new A.l($.o,t.D),r=new A.L(s,t.F),q=this.a
if((q.a.a&30)===0)q.U(new A.fk(r))
else r.L()
return A.wE(s)},
$S:50}
A.qb.prototype={
$1(a){return null},
$S:11}
A.fk.prototype={}
A.l5.prototype={
h_(a,b,c,d){return this.op(a,b,c,d)},
op(a,b,c,d){var s=0,r=A.i(t.u),q,p,o,n,m,l
var $async$h_=A.d(function(e,f){if(e===1)return A.e(f,r)
for(;;)switch(s){case 0:p=d==null?null:A.Q(d)
o=a.on(b,p!=null&&p.useMultipleCiphersVfs?"multipleciphers-"+c:c)
n=A.c2(!1,t.d)
m=A.u([],t.a6)
l=A.xi(o)
m.push(new A.aL(A.yY(),l,l.$ti.h("aL<C.T,I>")).O(n.gc4(n)))
q=new A.hW(o,n,m,A.T(t.eg,t.fK))
s=1
break
case 1:return A.f(q,r)}})
return A.h($async$h_,r)},
cq(a,b){throw A.c(A.vs(null))}}
A.hW.prototype={
m0(a,b){if(!a.a){a.a=!0
b.b.a.aK(new A.l6(a),t.P)}},
n(){var s,r,q,p=this
p.kx()
for(s=p.c,r=s.length,q=0;q<s.length;s.length===r||(0,A.a6)(s),++q)s[q].u()
p.b.n()
s=p.d
if(s!=null)s.b.close()},
cq(a,b){return this.nK(a,b)},
nK(a,b){var s=0,r=A.i(t.X),q,p=this,o,n,m,l,k,j,i
var $async$cq=A.d(function(c,d){if(c===1)return A.e(d,r)
for(;;)switch(s){case 0:i=A.Q(b.a)
case 3:switch(A.mS(B.ae,i.rawKind).a){case 0:s=5
break
case 4:s=6
break
case 1:s=7
break
case 2:s=8
break
case 3:s=9
break
case 5:s=10
break
default:s=4
break}break
case 5:case 6:throw A.c(A.R("This is a response, not a request"))
case 7:q=p.a.gd4()
s=1
break
case 8:s=11
return A.b(b.c.$1$1(new A.l7(p,i),t.P),$async$cq)
case 11:s=4
break
case 9:o=i.rawParameters
n=A.aX(o[0])
o=i.rawSql
m=p.e.cB(a,A.Ex())
if(n){m.h7()
p.m0(m,a)
l=A.xy()
k=p.b
l.b=m.b=new A.ao(k,A.p(k).h("ao<1>")).O(new A.l8(l,a,o))}else m.h7()
s=4
break
case 10:o=i.name
if(p.d==null){j=p.d=new A.i1(new v.G.BroadcastChannel("sqlite3_async_updates/"+o))
o=p.c
k=A.xi(p.a)
o.push(new A.aL(A.yY(),k,k.$ti.h("aL<C.T,I>")).O(j.gkg()))
k=p.b
o.push(j.goL().O(k.gc4(k)))}s=4
break
case 4:q={rawKind:"ok"}
s=1
break
case 1:return A.f(q,r)}})
return A.h($async$cq,r)},
gd5(){return this.a}}
A.l6.prototype={
$1(a){this.a.h7()},
$S:9}
A.l7.prototype={
$0(){var s,r,q,p,o,n,m,l=null,k=this.b
if(k.requireTransaction&&this.a.a.gd4())throw A.c(A.jh(A.At(A.uu(k,"rawSql")),l,0,"Transaction rolled back by earlier statement. Cannot execute",l,l,l))
s=this.a.a.ou(k.rawSql)
try{k=k.parameters
k=J.a0(t.ip.b(k)?k:new A.ae(k,A.a5(k).h("ae<1,v>")))
while(k.l()){r=k.gp()
q=s
p=r
o=p.parameters
p=p.parameterTypes
p.toString
n=new Uint8Array(p,0)
if(q.r||q.b.w)A.r(A.z(u.f))
if(!q.f){m=q.a
m.c.d.sqlite3_reset(m.b)
q.f=!0}q.hv(new A.f9(new A.cl(o,p,n).giH()))
q.hM()}}finally{s.n()}},
$S:1}
A.l8.prototype={
$1(a){var s=this.a.dQ(),r=a.a
r=A.an(r,A.p(r).c)
s.aJ(this.b.aX(A.v6(B.F,this.c,r)))},
$S:55}
A.eq.prototype={
h7(){var s=this.b
if(s!=null){this.b=null
s.u()}}}
A.jn.prototype={
gdD(){return A.ak(this.c)}}
A.p9.prototype={
gfV(){var s=this
if(s.c!==s.e)s.d=null
return s.d},
eK(a){var s,r=this,q=r.d=J.zG(a,r.b,r.c)
r.e=r.c
s=q!=null
if(s)r.e=r.c=q.gC()
return s},
iZ(a,b){var s
if(this.eK(a))return
if(b==null)if(a instanceof A.fo)b="/"+a.a+"/"
else{s=J.bb(a)
s=A.hK(s,"\\","\\\\")
b='"'+A.hK(s,'"','\\"')+'"'}this.hN(b)},
d8(a){return this.iZ(a,null)},
nx(){if(this.c===this.b.length)return
this.hN("no more input")},
nt(a,b,c){var s,r,q,p,o,n=this.b
if(c<0)A.r(A.ay("position must be greater than or equal to 0."))
else if(c>n.length)A.r(A.ay("position must be less than or equal to the string length."))
s=c+b>n.length
if(s)A.r(A.ay("position plus length must not go beyond the end of the string."))
s=this.a
r=A.u([0],t.t)
q=n.length
p=new A.oy(s,r,new Uint32Array(q))
p.kH(new A.bn(n),s)
o=c+b
if(o>q)A.r(A.ay("End "+o+u.D+p.gk(0)+"."))
else if(c<0)A.r(A.ay("Start may not be negative, was "+c+"."))
throw A.c(new A.jn(n,a,new A.ew(p,c,o)))},
hN(a){this.nt("expected "+a+".",0,this.c)}}
A.ef.prototype={
gk(a){return this.b},
i(a,b){if(b>=this.b)throw A.c(A.wG(b,this))
return this.a[b]},
m(a,b,c){var s
if(b>=this.b)throw A.c(A.wG(b,this))
s=this.a
s.$flags&2&&A.B(s)
s[b]=c},
sk(a,b){var s,r,q,p,o=this,n=o.b
if(b<n)for(s=o.a,r=s.$flags|0,q=b;q<n;++q){r&2&&A.B(s)
s[q]=0}else{n=o.a.length
if(b>n){if(n===0)p=new Uint8Array(b)
else p=o.f2(b)
B.e.af(p,0,o.b,o.a)
o.a=p}}o.b=b},
mq(a){var s,r=this,q=r.b
if(q===r.a.length)r.hW(q)
q=r.a
s=r.b++
q.$flags&2&&A.B(q)
q[s]=a},
q(a,b){var s,r=this,q=r.b
if(q===r.a.length)r.hW(q)
q=r.a
s=r.b++
q.$flags&2&&A.B(q)
q[s]=b},
hr(a,b,c){var s,r,q
if(t.j.b(a))c=c==null?J.aM(a):c
if(c!=null){this.lw(this.b,a,b,c)
return}for(s=J.a0(a),r=0;s.l();){q=s.gp()
if(r>=b)this.mq(q);++r}if(r<b)throw A.c(A.z("Too few elements"))},
lw(a,b,c,d){var s,r,q,p,o=this
if(t.j.b(b)){s=J.aa(b)
if(c>s.gk(b)||d>s.gk(b))throw A.c(A.z("Too few elements"))}r=d-c
q=o.b+r
o.lg(q)
s=o.a
p=a+r
B.e.Y(s,p,o.b+r,s,a)
B.e.Y(o.a,a,p,b,c)
o.b=q},
lg(a){var s,r=this
if(a<=r.a.length)return
s=r.f2(a)
B.e.af(s,0,r.b,r.a)
r.a=s},
f2(a){var s=this.a.length*2
if(a!=null&&s<a)s=a
else if(s<8)s=8
return new Uint8Array(s)},
hW(a){var s=this.f2(null)
B.e.af(s,0,a,this.a)
this.a=s},
Y(a,b,c,d,e){var s=this.b
if(c>s)throw A.c(A.ab(c,0,s,null,null))
s=this.a
if(d instanceof A.bd)B.e.Y(s,b,c,d.a,e)
else B.e.Y(s,b,c,d,e)},
af(a,b,c,d){return this.Y(0,b,c,d,0)}}
A.k2.prototype={}
A.bd.prototype={}
A.v7.prototype={}
A.eu.prototype={
gaw(){return!0},
B(a,b,c,d){return A.aC(this.a,this.b,a,!1,this.$ti.c)},
O(a){return this.B(a,null,null,null)},
az(a,b,c){return this.B(a,null,b,c)},
bq(a,b,c){return this.B(a,b,c,null)}}
A.ev.prototype={
u(){var s=this,r=A.n2(null,t.H)
if(s.b==null)return r
s.fu()
s.d=s.b=null
return r},
bt(a){var s,r=this
if(r.b==null)throw A.c(A.z("Subscription has been canceled."))
r.fu()
s=A.yw(new A.rt(a),t.m)
s=s==null?null:A.bz(s)
r.d=s
r.fs()},
dk(a){},
aJ(a){var s=this
if(s.b==null)return;++s.a
s.fu()
if(a!=null)a.J(s.gbM())},
aj(){return this.aJ(null)},
am(){var s=this
if(s.b==null||s.a<=0)return;--s.a
s.fs()},
fs(){var s=this,r=s.d
if(r!=null&&s.a<=0)s.b.addEventListener(s.c,r,!1)},
fu(){var s=this.d
if(s!=null)this.b.removeEventListener(this.c,s,!1)},
$iac:1}
A.rs.prototype={
$1(a){return this.a.$1(a)},
$S:2}
A.rt.prototype={
$1(a){return this.a.$1(a)},
$S:2};(function aliases(){var s=J.cp.prototype
s.kt=s.j
s=A.b1.prototype
s.kp=s.jb
s.kq=s.jc
s.ks=s.je
s.kr=s.jd
s=A.ca.prototype
s.ky=s.ak
s=A.av.prototype
s.bR=s.N
s.eN=s.ab
s.ho=s.a_
s=A.cc.prototype
s.kz=s.hF
s.kA=s.hT
s.kB=s.ij
s=A.y.prototype
s.hn=s.Y
s=A.af.prototype
s.hm=s.bk
s=A.hv.prototype
s.kC=s.n
s=A.hZ.prototype
s.hl=s.nA
s=A.e9.prototype
s.kv=s.a0
s.ku=s.D
s=A.cB.prototype
s.kx=s.n
s=A.I.prototype
s.kw=s.fD})();(function installTearOffs(){var s=hunkHelpers._static_2,r=hunkHelpers._instance_0u,q=hunkHelpers._instance_1u,p=hunkHelpers.installInstanceTearOff,o=hunkHelpers._static_1,n=hunkHelpers._static_0,m=hunkHelpers._instance_1i,l=hunkHelpers._instance_2u,k=hunkHelpers.installStaticTearOff
s(J,"CU","Aq",32)
var j
r(j=A.dK.prototype,"ge5","u",19)
q(j,"gkT","kU",5)
p(j,"gep",0,0,null,["$1","$0"],["aJ","aj"],35,0,0)
r(j,"gbM","am",0)
o(A,"D6","D9",26)
o(A,"Dz","Bs",13)
o(A,"DA","Bt",13)
o(A,"DB","Bu",13)
o(A,"DC","Db",17)
n(A,"yy","Dq",0)
o(A,"DD","Dc",12)
s(A,"DE","De",6)
n(A,"uj","Dd",0)
r(j=A.dm.prototype,"gcT","b2",0)
r(j,"gcU","b3",0)
m(j=A.ca.prototype,"gc4","q",5)
r(j,"gaG","n",3)
q(j,"geQ","N",5)
l(j,"gdG","ab",6)
r(j,"geW","a_",0)
p(A.dn.prototype,"gmP",0,1,null,["$2","$1"],["b8","a9"],38,0,0)
l(A.l.prototype,"gf0","l4",6)
m(j=A.cE.prototype,"gc4","q",5)
p(j,"gfz",0,1,null,["$2","$1"],["ag","mE"],38,0,0)
r(j,"gaG","n",19)
q(j,"geQ","N",5)
l(j,"gdG","ab",6)
r(j,"geW","a_",0)
r(j=A.cD.prototype,"gcT","b2",0)
r(j,"gcU","b3",0)
p(j=A.av.prototype,"gep",0,0,null,["$1","$0"],["aJ","aj"],39,0,0)
r(j,"gbM","am",0)
r(j,"ge5","u",19)
r(j,"gcT","b2",0)
r(j,"gcU","b3",0)
p(j=A.et.prototype,"gep",0,0,null,["$1","$0"],["aJ","aj"],39,0,0)
r(j,"gbM","am",0)
r(j,"ge5","u",19)
r(j,"gi4","lR",0)
q(j=A.bO.prototype,"glJ","lK",5)
l(j,"glN","lO",6)
r(j,"glL","lM",0)
r(j=A.ex.prototype,"gcT","b2",0)
r(j,"gcU","b3",0)
q(j,"gfa","fb",5)
l(j,"gfe","ff",56)
r(j,"gfc","fd",0)
r(j=A.eF.prototype,"gcT","b2",0)
r(j,"gcU","b3",0)
q(j,"gfa","fb",5)
l(j,"gfe","ff",6)
r(j,"gfc","fd",0)
s(A,"w_","CH",24)
o(A,"w0","CI",25)
s(A,"DI","Ax",32)
o(A,"DL","CJ",41)
o(A,"DK","BV",168)
m(j=A.jQ.prototype,"gc4","q",5)
r(j,"gaG","n",0)
o(A,"yB","E_",25)
s(A,"yA","DZ",24)
o(A,"DM","Bj",15)
k(A,"Ee",2,null,["$1$2","$2"],["yJ",function(a,b){return A.yJ(a,b,t.q)}],169,0)
r(j=A.fJ.prototype,"glP","lQ",0)
r(j,"gmm","mn",0)
r(j,"gmo","mp",0)
r(j,"gml","io",33)
l(j=A.fa.prototype,"gns","bG",24)
q(j,"gnW","fQ",25)
q(j,"go1","o2",17)
o(A,"DG","zP",15)
o(A,"E5","Am",170)
o(A,"Eq","BF",171)
o(A,"Er","AQ",172)
r(A.kk.prototype,"gny","j_",0)
r(A.ck.prototype,"goh","fX",0)
r(A.jE.prototype,"gaG","n",3)
q(A.j2.prototype,"goN","oO",20)
q(j=A.ib.prototype,"gof","og",8)
l(j,"goa","ob",102)
p(j,"gpl",0,5,null,["$5"],["pm"],103,0,0)
p(j,"gp8",0,3,null,["$3"],["p9"],104,0,0)
p(j,"goX",0,4,null,["$4"],["oY"],45,0,0)
p(j,"gph",0,4,null,["$4"],["pi"],45,0,0)
p(j,"gpn",0,3,null,["$3"],["po"],106,0,0)
l(j,"gps","pt",46)
l(j,"gp6","p7",46)
q(j,"gp0","p5",30)
p(j,"gpp",0,4,null,["$4"],["pq"],47,0,0)
p(j,"gpA",0,4,null,["$4"],["pB"],47,0,0)
l(j,"gpw","px",110)
l(j,"gpu","pv",10)
l(j,"gpd","pe",10)
l(j,"gpf","pg",10)
l(j,"gpj","pk",10)
l(j,"gpy","pz",10)
l(j,"goZ","p_",10)
q(j,"geF","pa",30)
p(j,"gpb",0,3,null,["$3"],["pc"],112,0,0)
q(j,"geH","pr",30)
q(j,"gna","nb",13)
q(j,"gn3","n4",113)
p(j,"gn8",0,5,null,["$5"],["n9"],114,0,0)
p(j,"gn6",0,4,null,["$4"],["n7"],115,0,0)
p(j,"gng",0,4,null,["$4"],["nh"],23,0,0)
p(j,"gnk",0,4,null,["$4"],["nl"],23,0,0)
p(j,"gni",0,4,null,["$4"],["nj"],23,0,0)
l(j,"gnm","nn",48)
l(j,"gne","nf",48)
p(j,"gnc",0,5,null,["$5"],["nd"],118,0,0)
l(j,"gn1","n2",119)
l(j,"gn_","n0",120)
p(j,"gmY",0,3,null,["$3"],["mZ"],121,0,0)
r(j=A.cn.prototype,"gaG","n",3)
r(j,"gnC","j2",3)
r(A.e7.prototype,"gaG","n",0)
q(A.jF.prototype,"gj6","fK",2)
r(A.ic.prototype,"gls","lt",0)
q(A.cl.prototype,"giH","iI",141)
q(A.eo.prototype,"gj6","fK",2)
o(A,"yY","Bc",125)
r(A.dx.prototype,"gmG","mH",0)
q(A.i1.prototype,"gkg","ap",55)
q(A.jw.prototype,"gnS","fL",166)
n(A,"Ex","BH",116)
r(j=A.ev.prototype,"ge5","u",3)
p(j,"gep",0,0,null,["$1","$0"],["aJ","aj"],35,0,0)
r(j,"gbM","am",0)})();(function inheritance(){var s=hunkHelpers.mixin,r=hunkHelpers.inherit,q=hunkHelpers.inheritMany
r(A.k,null)
q(A.k,[A.vg,J.W,A.fD,J.dJ,A.C,A.dK,A.m,A.i5,A.cU,A.F,A.V,A.y,A.ou,A.as,A.cr,A.ek,A.il,A.jo,A.j7,A.ih,A.jD,A.iQ,A.fh,A.jt,A.fM,A.hm,A.f4,A.ey,A.cw,A.px,A.iS,A.fd,A.ht,A.nJ,A.d2,A.b3,A.iG,A.fo,A.eC,A.jI,A.fL,A.tr,A.jR,A.kA,A.br,A.jZ,A.ty,A.tw,A.h_,A.jK,A.hd,A.kv,A.a2,A.av,A.ca,A.jp,A.bM,A.dn,A.bg,A.l,A.jJ,A.jk,A.cE,A.kw,A.jL,A.fZ,A.jU,A.ro,A.eD,A.et,A.bO,A.h9,A.tM,A.tL,A.tN,A.c8,A.dk,A.qq,A.k_,A.t8,A.eA,A.k6,A.aG,A.kz,A.fu,A.k7,A.jm,A.i8,A.af,A.lu,A.qP,A.i7,A.dp,A.t3,A.ts,A.kC,A.cI,A.az,A.jX,A.bS,A.bT,A.rp,A.iT,A.fI,A.jW,A.aT,A.iv,A.K,A.D,A.ku,A.Z,A.hC,A.pJ,A.bh,A.im,A.vw,A.iR,A.rY,A.rZ,A.ii,A.fV,A.fJ,A.eG,A.S,A.fa,A.eJ,A.eB,A.iI,A.iP,A.ju,A.l1,A.bQ,A.hY,A.hZ,A.lg,A.fv,A.cq,A.dX,A.dY,A.lY,A.pa,A.o_,A.iV,A.hO,A.ct,A.f8,A.f7,A.e2,A.de,A.d0,A.I,A.dL,A.lF,A.cb,A.ft,A.dR,A.lE,A.fS,A.m1,A.mO,A.ff,A.dM,A.fb,A.f2,A.fj,A.fQ,A.nC,A.fN,A.lD,A.aK,A.dP,A.em,A.oV,A.qu,A.cu,A.fU,A.fP,A.fi,A.f3,A.kk,A.vE,A.pk,A.ck,A.ee,A.fY,A.hr,A.h6,A.h3,A.jE,A.oe,A.j2,A.i6,A.rq,A.mv,A.o3,A.oy,A.ja,A.e9,A.n8,A.aP,A.bw,A.bt,A.jd,A.b7,A.cx,A.dc,A.mw,A.cF,A.oA,A.cV,A.aB,A.i_,A.m3,A.ko,A.kl,A.nx,A.f9,A.c5,A.fH,A.pY,A.pT,A.q_,A.pZ,A.dj,A.cA,A.ib,A.dq,A.pU,A.l9,A.hc,A.ru,A.k8,A.k1,A.ta,A.pO,A.dN,A.oq,A.f1,A.jS,A.j1,A.mu,A.ia,A.cB,A.io,A.n7,A.bV,A.ic,A.dZ,A.cW,A.o4,A.d8,A.rn,A.tK,A.rl,A.hu,A.ep,A.id,A.ql,A.tf,A.je,A.bB,A.jv,A.fE,A.dx,A.i1,A.jw,A.q8,A.fk,A.eq,A.p9,A.v7,A.ev])
q(J.W,[J.ix,J.dV,J.ag,J.aN,J.d_,J.dW,J.co])
q(J.ag,[J.cp,J.w,A.e_,A.fy])
q(J.cp,[J.iW,J.dg,J.b_])
r(J.iw,A.fD)
r(J.nF,J.w)
q(J.dW,[J.fn,J.iy])
q(A.C,[A.cT,A.eH,A.fK,A.dr,A.bx,A.b8,A.c9,A.eY,A.eu])
q(A.m,[A.cC,A.x,A.bY,A.c7,A.fe,A.df,A.c0,A.fX,A.fB,A.he,A.jH,A.kt,A.eI,A.d3])
q(A.cC,[A.cR,A.hF])
r(A.h8,A.cR)
r(A.h2,A.hF)
q(A.cU,[A.lJ,A.lB,A.lI,A.ny,A.pm,A.ux,A.uz,A.qG,A.qF,A.tQ,A.tP,A.tt,A.tv,A.tu,A.n5,A.mY,A.n1,A.rx,A.rw,A.rI,A.rM,A.oL,A.oS,A.oQ,A.oT,A.oO,A.qt,A.rk,A.t7,A.nO,A.m0,A.mR,A.qU,A.mZ,A.uB,A.uS,A.uT,A.oI,A.oH,A.lx,A.lz,A.lf,A.ll,A.tS,A.lv,A.nU,A.up,A.lZ,A.m_,A.uh,A.uQ,A.uP,A.u1,A.lt,A.lr,A.ls,A.ln,A.lG,A.m2,A.pj,A.uI,A.uG,A.uk,A.uZ,A.pM,A.oZ,A.p6,A.p5,A.p_,A.p0,A.p1,A.p4,A.p3,A.oX,A.qv,A.qB,A.qA,A.qz,A.qw,A.qx,A.lV,A.lW,A.pd,A.pf,A.pg,A.ph,A.pI,A.qk,A.qj,A.uD,A.uE,A.uC,A.na,A.n9,A.nb,A.nd,A.nf,A.nc,A.nt,A.oE,A.mE,A.to,A.uO,A.uU,A.uV,A.l4,A.ri,A.rj,A.lM,A.lN,A.lR,A.lS,A.lT,A.mU,A.lc,A.la,A.rR,A.rV,A.rW,A.nw,A.nu,A.rQ,A.ox,A.pP,A.pQ,A.pR,A.pS,A.o9,A.oa,A.o8,A.o7,A.o6,A.oj,A.of,A.om,A.on,A.og,A.q6,A.mH,A.nW,A.mT,A.or,A.os,A.um,A.lK,A.lL,A.lO,A.lP,A.lQ,A.tZ,A.r4,A.r2,A.r8,A.rb,A.r0,A.tg,A.th,A.tj,A.oD,A.oB,A.oC,A.pG,A.pF,A.ub,A.ue,A.pu,A.po,A.pp,A.pq,A.pv,A.pt,A.q2,A.q5,A.q4,A.q3,A.q1,A.lj,A.lh,A.li,A.qV,A.pC,A.qc,A.qb,A.l6,A.l8,A.rs,A.rt])
q(A.lJ,[A.qZ,A.lC,A.lX,A.nG,A.uy,A.tR,A.ui,A.n6,A.mX,A.ry,A.rJ,A.rN,A.qD,A.tT,A.rO,A.nK,A.nQ,A.mQ,A.t4,A.qT,A.pK,A.n0,A.n_,A.lw,A.ly,A.lA,A.le,A.nV,A.mP,A.v_,A.p8,A.qy,A.vm,A.ne,A.rX,A.q7,A.rf,A.qo,A.pH,A.ug,A.u_])
r(A.ae,A.h2)
q(A.F,[A.cS,A.b1,A.cc,A.k3])
q(A.V,[A.d1,A.c3,A.iz,A.js,A.j4,A.jV,A.e1,A.fq,A.hU,A.a1,A.fR,A.jr,A.aW,A.i9,A.iH])
q(A.y,[A.eg,A.ei,A.cl,A.ef])
r(A.bn,A.eg)
q(A.lI,[A.uN,A.qH,A.qI,A.tx,A.tO,A.qN,A.qO,A.qK,A.qL,A.qM,A.qJ,A.n3,A.rz,A.rE,A.rD,A.rB,A.rA,A.rH,A.rG,A.rF,A.rK,A.rL,A.oM,A.oR,A.oP,A.oU,A.oN,A.tn,A.tm,A.qC,A.qY,A.qX,A.tb,A.t9,A.tU,A.tV,A.qs,A.qr,A.u5,A.tH,A.tG,A.u2,A.u0,A.oJ,A.oK,A.oG,A.lk,A.u3,A.u4,A.nT,A.nN,A.l_,A.l0,A.uJ,A.uH,A.uK,A.uL,A.uM,A.uY,A.pN,A.oY,A.oW,A.p7,A.p2,A.tY,A.oo,A.td,A.pl,A.lU,A.pi,A.pe,A.qf,A.qg,A.qh,A.qi,A.ns,A.ng,A.nn,A.no,A.np,A.nq,A.nl,A.nm,A.nh,A.ni,A.nj,A.nk,A.nr,A.rP,A.mF,A.mG,A.mC,A.mB,A.mD,A.my,A.mx,A.mz,A.mA,A.tp,A.tq,A.uW,A.mf,A.mb,A.mk,A.mm,A.mp,A.me,A.md,A.mn,A.mt,A.mr,A.mq,A.mj,A.mi,A.ml,A.ms,A.mc,A.mg,A.mh,A.mo,A.m9,A.m8,A.ma,A.m7,A.m6,A.m5,A.l2,A.l3,A.pV,A.lb,A.rS,A.rT,A.rU,A.rv,A.nv,A.ob,A.ok,A.ol,A.oh,A.oi,A.mI,A.mJ,A.nY,A.nX,A.rd,A.rh,A.re,A.rg,A.r1,A.r7,A.ra,A.r3,A.r9,A.rc,A.r5,A.r6,A.mM,A.mL,A.mK,A.qm,A.qn,A.tk,A.ti,A.tl,A.uc,A.ud,A.u7,A.u6,A.uf,A.u8,A.u9,A.ua,A.pw,A.pr,A.ps,A.pn,A.q0,A.tE,A.tD,A.tC,A.tB,A.pD,A.pE,A.qa,A.l7])
q(A.x,[A.X,A.cY,A.b2,A.bX,A.aF,A.hb])
q(A.X,[A.dd,A.a8,A.da,A.fs,A.k4])
r(A.bU,A.bY)
r(A.fc,A.df)
r(A.dQ,A.c0)
q(A.hm,[A.k9,A.ka,A.kb,A.kc])
r(A.hn,A.k9)
q(A.ka,[A.N,A.ho,A.hp,A.kd,A.eE,A.ke,A.kf])
q(A.kb,[A.hq,A.kg,A.kh,A.ki])
r(A.kj,A.kc)
r(A.bo,A.f4)
q(A.cw,[A.f5,A.hs])
r(A.f6,A.f5)
r(A.fm,A.ny)
r(A.fC,A.c3)
q(A.pm,[A.oF,A.eZ])
q(A.b1,[A.fp,A.hf])
r(A.bE,A.e_)
q(A.fy,[A.fx,A.e0])
q(A.e0,[A.hh,A.hj])
r(A.hi,A.hh)
r(A.cs,A.hi)
r(A.hk,A.hj)
r(A.b5,A.hk)
q(A.cs,[A.iJ,A.iK])
q(A.b5,[A.iL,A.iM,A.iN,A.iO,A.fz,A.fA,A.d5])
r(A.hw,A.jV)
r(A.a4,A.eH)
r(A.ao,A.a4)
q(A.av,[A.cD,A.ex,A.eF])
r(A.dm,A.cD)
q(A.ca,[A.dw,A.h0])
q(A.dn,[A.a9,A.L])
q(A.cE,[A.bK,A.cG])
r(A.ks,A.fZ)
q(A.jU,[A.bv,A.es])
r(A.hg,A.bK)
q(A.b8,[A.cf,A.aL])
q(A.jk,[A.kr,A.nI])
q(A.cc,[A.dt,A.h4])
r(A.cd,A.hs)
r(A.hB,A.fu)
r(A.dh,A.hB)
q(A.jm,[A.hv,A.tz,A.t6,A.dv])
r(A.t0,A.hv)
q(A.i8,[A.cZ,A.ld,A.nH])
q(A.cZ,[A.hR,A.iD,A.jz])
q(A.af,[A.ky,A.kx,A.hX,A.iC,A.iB,A.jB,A.jA])
q(A.ky,[A.hT,A.iF])
q(A.kx,[A.hS,A.iE])
q(A.lu,[A.rr,A.te,A.qQ,A.jP,A.jQ,A.k5,A.kB])
r(A.qW,A.qP)
r(A.qE,A.qQ)
r(A.iA,A.fq)
r(A.t1,A.i7)
r(A.t2,A.t3)
r(A.t5,A.k5)
r(A.ez,A.t6)
r(A.kD,A.kC)
r(A.tI,A.kD)
q(A.a1,[A.e4,A.fl])
r(A.jT,A.hC)
r(A.db,A.eJ)
r(A.cv,A.bQ)
q(A.hY,[A.i2,A.e5])
r(A.cQ,A.fK)
r(A.op,A.hZ)
r(A.jG,A.op)
r(A.hP,A.jG)
q(A.lg,[A.e6,A.cz])
r(A.jl,A.cz)
r(A.f0,A.S)
r(A.nD,A.pa)
q(A.nD,[A.o0,A.pL,A.qe])
q(A.rp,[A.fT,A.pb,A.dO,A.ad,A.eb,A.nZ,A.dS,A.fw,A.cm,A.bu,A.fg,A.cy,A.bR])
r(A.bc,A.I)
q(A.cb,[A.hl,A.en,A.h7])
q(A.lD,[A.fr,A.d9])
q(A.mv,[A.l5,A.rm])
r(A.o1,A.l5)
r(A.iq,A.ja)
q(A.e9,[A.ew,A.jc])
r(A.e8,A.jd)
r(A.c1,A.jc)
q(A.cx,[A.jj,A.ea,A.ji])
r(A.ed,A.cV)
r(A.i0,A.aB)
q(A.i0,[A.is,A.cn,A.e7])
q(A.i_,[A.k0,A.kq])
r(A.km,A.m3)
r(A.kn,A.km)
r(A.bF,A.kn)
r(A.kp,A.ko)
r(A.aV,A.kp)
q(A.aG,[A.dl,A.aD])
r(A.eh,A.oA)
q(A.aD,[A.ha,A.h5,A.er,A.eL])
r(A.o5,A.oq)
q(A.o5,[A.jF,A.eo])
r(A.m4,A.ia)
r(A.bm,A.d8)
r(A.jf,A.je)
r(A.jg,A.jf)
r(A.fF,A.fE)
r(A.jC,A.jg)
r(A.ce,A.jv)
r(A.hW,A.cB)
r(A.jn,A.e8)
r(A.k2,A.ef)
r(A.bd,A.k2)
s(A.eg,A.jt)
s(A.hF,A.y)
s(A.hh,A.y)
s(A.hi,A.fh)
s(A.hj,A.y)
s(A.hk,A.fh)
s(A.bK,A.jL)
s(A.cG,A.kw)
s(A.hB,A.kz)
s(A.kD,A.jm)
s(A.jG,A.l1)
s(A.km,A.y)
s(A.kn,A.iP)
s(A.ko,A.ju)
s(A.kp,A.F)})()
var v={G:typeof self!="undefined"?self:globalThis,typeUniverse:{eC:new Map(),tR:{},eT:{},tPV:{},sEA:[]},mangledGlobalNames:{a:"int",Y:"double",bP:"num",j:"String",G:"bool",D:"Null",t:"List",k:"Object",a3:"Map",v:"JSObject"},mangledNames:{},types:["~()","D()","~(v)","n<~>()","a()","~(k?)","~(k,aj)","D(k,aj)","~(a)","D(~)","a(aO,a)","D(@)","~(@)","~(~())","D(v)","j(j)","n<bF>()","G(k?)","v()","n<@>()","n<~>(n<~>)","n<~>(hc)","~(~)","~(j0,a,a,a)","G(k?,k?)","a(k?)","j(d4)","G(j)","n<ct?>(n<~>)","G(aP)","a(aO)","n<ac<~>>()","a(@,@)","n<~>?()","~(j,j)","~([n<@>?])","~(dX)","n<j>(aJ)","~(k[aj?])","~([n<~>?])","n<D>()","@(@)","~(k?,k?)","j(k?)","@()","a(aB,a,a,a)","a(aB,a)","a(aO,a,a,aN)","~(j0,a)","v(G)","v(k)","~(b7)","G()","n<cB>()","~(dx)","~(I)","~(@,aj)","G(cb)","D(~())","K<j,+atLast,priority,sinceLast,targetCount(a,a,a,a)>(j,k?)","j(+(j,k?))","n<~>(ac<~>)","n<+immediateRestart(G)>()","~(a,@)","n<j>()","n<j>(n<~>)","l<@>?()","n<e6>(n<~>)","n<dU?>()","n<dU?>(aJ)","a3<j,@>(+name,parameters(j,j))","n<+immediateRestart(G)>(n<~>)","n<~>(aJ)","C<aR>?(cz)","D(ct?)","ee()","n<+(k,D)>(ad,k,n<~>)","e5()","G(j,j)","D(@,aj)","~(aK)","~(j)","+name,parameters(j,j)(k?)","n<~>(v)","n<+(D,D)>()","n<+(v,D)>()","n<+(bE?,w<k?>?)>()","+(k?,w<k?>?)/()","a(j)","j?()","a(bw)","~(@,@)","k(bw)","k(aP)","a(aP,aP)","t<bw>(K<k,t<aP>>)","D(j,j[k?])","c1()","~(bZ<t<a>>)","~(a,j,a)","~(t<a>)","~(c8,dk,c8,~())","~(aN,a)","aO?(aB,a,a,a,a)","a(aB,a,a)","fv()","a(aB?,a,a)","k?(~)","dp<@,@>(ah<@>)","@(j)","a(aO,aN)","Z(Z,j)","a(aO,a,a)","a(a())","~(~(a,j,a),a,a,a,aN)","a(a(cx),a,a,a)","eq()","dY()","a(j0,a,a,a,a)","a(a(a),a)","a(vo,a)","a(vo,a,a)","ea()","j(Z)","v(w<k?>)","I(bs<j>)","v(v?)","~(cP)","n<~>(a,be)","n<~>(a)","be()","n<v>(j)","~(ws)","D(bV)","n<D>(v)","k(k,aj)","j(j?)","D(k?,aj)","j?(k?)","@(@,j)","j?(j?)","~(cV)","v(v)","n<0^>(0^())<k?>","n<v>()","dP(k?)","0&(j,a?)","n<ac<b7>>()","bc(I)","G(bc)","G(ep)","k?(k?)","n<cW>()","0&(k?,aj)","n<bF>(aA)","n<aV?>(aA)","I(I,I)","C<I>(C<I>)","G(I)","n<a?>(aA)","~(bZ<bs<j>>)","v?()","0&(bm,aj)","n<G>(aJ)","I?(v)","G(I?)","n<k?>(k?)","D(b_,b_)","ez(ah<j>)","0^(0^,0^)<bP>","ar(a3<j,k?>)","em(ah<be>)","cu(k)","a(a,a)","a(a)"],interceptorsByTag:null,leafTags:null,arrayRti:Symbol("$ti"),rttc:{"1;immediateRestart":a=>b=>b instanceof A.hn&&a.b(b.a),"2;":(a,b)=>c=>c instanceof A.N&&a.b(c.a)&&b.b(c.b),"2;basicSupport,supportsReadWriteUnsafe":(a,b)=>c=>c instanceof A.ho&&a.b(c.a)&&b.b(c.b),"2;controller,sync":(a,b)=>c=>c instanceof A.hp&&a.b(c.a)&&b.b(c.b),"2;downloaded,total":(a,b)=>c=>c instanceof A.kd&&a.b(c.a)&&b.b(c.b),"2;file,outFlags":(a,b)=>c=>c instanceof A.eE&&a.b(c.a)&&b.b(c.b),"2;name,parameters":(a,b)=>c=>c instanceof A.ke&&a.b(c.a)&&b.b(c.b),"2;result,resultCode":(a,b)=>c=>c instanceof A.kf&&a.b(c.a)&&b.b(c.b),"3;":(a,b,c)=>d=>d instanceof A.hq&&a.b(d.a)&&b.b(d.b)&&c.b(d.c),"3;autocommit,lastInsertRowid,result":(a,b,c)=>d=>d instanceof A.kg&&a.b(d.a)&&b.b(d.b)&&c.b(d.c),"3;connectName,connectPort,lockName":(a,b,c)=>d=>d instanceof A.kh&&a.b(d.a)&&b.b(d.b)&&c.b(d.c),"3;hasSynced,lastSyncedAt,priority":(a,b,c)=>d=>d instanceof A.ki&&a.b(d.a)&&b.b(d.b)&&c.b(d.c),"4;atLast,priority,sinceLast,targetCount":a=>b=>b instanceof A.kj&&A.Ef(a,b.a)}}
A.Cf(v.typeUniverse,JSON.parse('{"b_":"cp","iW":"cp","dg":"cp","EL":"e_","aN":{"W":[]},"w":{"t":["1"],"ag":[],"x":["1"],"W":[],"v":[],"m":["1"],"aE":["1"]},"ix":{"W":[],"G":[],"a_":[]},"dV":{"W":[],"D":[],"a_":[]},"ag":{"W":[],"v":[]},"cp":{"ag":[],"W":[],"v":[]},"d_":{"W":[]},"iw":{"fD":[]},"nF":{"w":["1"],"t":["1"],"ag":[],"x":["1"],"W":[],"v":[],"m":["1"],"aE":["1"]},"dW":{"Y":[],"W":[],"a7":["bP"]},"fn":{"Y":[],"a":[],"W":[],"a7":["bP"],"a_":[]},"iy":{"Y":[],"W":[],"a7":["bP"],"a_":[]},"co":{"j":[],"W":[],"a7":["j"],"aE":["@"],"a_":[]},"cT":{"C":["2"],"C.T":"2"},"dK":{"ac":["2"]},"cC":{"m":["2"]},"cR":{"cC":["1","2"],"m":["2"],"m.E":"2"},"h8":{"cR":["1","2"],"cC":["1","2"],"x":["2"],"m":["2"],"m.E":"2"},"h2":{"y":["2"],"t":["2"],"cC":["1","2"],"x":["2"],"m":["2"]},"ae":{"h2":["1","2"],"y":["2"],"t":["2"],"cC":["1","2"],"x":["2"],"m":["2"],"y.E":"2","m.E":"2"},"cS":{"F":["3","4"],"a3":["3","4"],"F.V":"4","F.K":"3"},"d1":{"V":[]},"bn":{"y":["a"],"t":["a"],"x":["a"],"m":["a"],"y.E":"a"},"x":{"m":["1"]},"X":{"x":["1"],"m":["1"]},"dd":{"X":["1"],"x":["1"],"m":["1"],"X.E":"1","m.E":"1"},"bY":{"m":["2"],"m.E":"2"},"bU":{"bY":["1","2"],"x":["2"],"m":["2"],"m.E":"2"},"a8":{"X":["2"],"x":["2"],"m":["2"],"X.E":"2","m.E":"2"},"c7":{"m":["1"],"m.E":"1"},"fe":{"m":["2"],"m.E":"2"},"df":{"m":["1"],"m.E":"1"},"fc":{"df":["1"],"x":["1"],"m":["1"],"m.E":"1"},"c0":{"m":["1"],"m.E":"1"},"dQ":{"c0":["1"],"x":["1"],"m":["1"],"m.E":"1"},"cY":{"x":["1"],"m":["1"],"m.E":"1"},"fX":{"m":["1"],"m.E":"1"},"fB":{"m":["1"],"m.E":"1"},"eg":{"y":["1"],"t":["1"],"x":["1"],"m":["1"]},"da":{"X":["1"],"x":["1"],"m":["1"],"X.E":"1","m.E":"1"},"f4":{"a3":["1","2"]},"bo":{"f4":["1","2"],"a3":["1","2"]},"he":{"m":["1"],"m.E":"1"},"f5":{"cw":["1"],"bs":["1"],"x":["1"],"m":["1"]},"f6":{"cw":["1"],"bs":["1"],"x":["1"],"m":["1"]},"fC":{"c3":[],"V":[]},"iz":{"V":[]},"js":{"V":[]},"iS":{"J":[]},"ht":{"aj":[]},"j4":{"V":[]},"b1":{"F":["1","2"],"a3":["1","2"],"F.V":"2","F.K":"1"},"b2":{"x":["1"],"m":["1"],"m.E":"1"},"bX":{"x":["1"],"m":["1"],"m.E":"1"},"aF":{"x":["K<1,2>"],"m":["K<1,2>"],"m.E":"K<1,2>"},"fp":{"b1":["1","2"],"F":["1","2"],"a3":["1","2"],"F.V":"2","F.K":"1"},"eC":{"j_":[],"d4":[]},"jH":{"m":["j_"],"m.E":"j_"},"fL":{"d4":[]},"kt":{"m":["d4"],"m.E":"d4"},"bE":{"ag":[],"W":[],"v":[],"cP":[],"a_":[]},"e_":{"ag":[],"W":[],"v":[],"cP":[],"a_":[]},"fy":{"ag":[],"W":[],"v":[]},"kA":{"cP":[]},"fx":{"ag":[],"v4":[],"W":[],"v":[],"a_":[]},"e0":{"b0":["1"],"ag":[],"W":[],"v":[],"aE":["1"]},"cs":{"y":["Y"],"t":["Y"],"b0":["Y"],"ag":[],"x":["Y"],"W":[],"v":[],"aE":["Y"],"m":["Y"]},"b5":{"y":["a"],"t":["a"],"b0":["a"],"ag":[],"x":["a"],"W":[],"v":[],"aE":["a"],"m":["a"]},"iJ":{"cs":[],"mV":[],"y":["Y"],"t":["Y"],"b0":["Y"],"ag":[],"x":["Y"],"W":[],"v":[],"aE":["Y"],"m":["Y"],"a_":[],"y.E":"Y"},"iK":{"cs":[],"mW":[],"y":["Y"],"t":["Y"],"b0":["Y"],"ag":[],"x":["Y"],"W":[],"v":[],"aE":["Y"],"m":["Y"],"a_":[],"y.E":"Y"},"iL":{"b5":[],"nz":[],"y":["a"],"t":["a"],"b0":["a"],"ag":[],"x":["a"],"W":[],"v":[],"aE":["a"],"m":["a"],"a_":[],"y.E":"a"},"iM":{"b5":[],"nA":[],"y":["a"],"t":["a"],"b0":["a"],"ag":[],"x":["a"],"W":[],"v":[],"aE":["a"],"m":["a"],"a_":[],"y.E":"a"},"iN":{"b5":[],"nB":[],"y":["a"],"t":["a"],"b0":["a"],"ag":[],"x":["a"],"W":[],"v":[],"aE":["a"],"m":["a"],"a_":[],"y.E":"a"},"iO":{"b5":[],"pz":[],"y":["a"],"t":["a"],"b0":["a"],"ag":[],"x":["a"],"W":[],"v":[],"aE":["a"],"m":["a"],"a_":[],"y.E":"a"},"fz":{"b5":[],"pA":[],"y":["a"],"t":["a"],"b0":["a"],"ag":[],"x":["a"],"W":[],"v":[],"aE":["a"],"m":["a"],"a_":[],"y.E":"a"},"fA":{"b5":[],"pB":[],"y":["a"],"t":["a"],"b0":["a"],"ag":[],"x":["a"],"W":[],"v":[],"aE":["a"],"m":["a"],"a_":[],"y.E":"a"},"d5":{"b5":[],"be":[],"y":["a"],"t":["a"],"b0":["a"],"ag":[],"x":["a"],"W":[],"v":[],"aE":["a"],"m":["a"],"a_":[],"y.E":"a"},"jV":{"V":[]},"hw":{"c3":[],"V":[]},"a2":{"V":[]},"l":{"n":["1"]},"bZ":{"bG":["1"],"ah":["1"]},"bG":{"ah":["1"]},"av":{"ac":["1"],"av.T":"1"},"h_":{"cX":["1"]},"eI":{"m":["1"],"m.E":"1"},"ao":{"a4":["1"],"eH":["1"],"C":["1"],"C.T":"1"},"dm":{"cD":["1"],"av":["1"],"ac":["1"],"av.T":"1"},"ca":{"bG":["1"],"ah":["1"]},"dw":{"ca":["1"],"bG":["1"],"ah":["1"]},"h0":{"ca":["1"],"bG":["1"],"ah":["1"]},"jp":{"J":[]},"e1":{"V":[]},"dn":{"cX":["1"]},"a9":{"dn":["1"],"cX":["1"]},"L":{"dn":["1"],"cX":["1"]},"fK":{"C":["1"]},"cE":{"bG":["1"],"ah":["1"]},"bK":{"cE":["1"],"bG":["1"],"ah":["1"]},"cG":{"cE":["1"],"bG":["1"],"ah":["1"]},"a4":{"eH":["1"],"C":["1"],"C.T":"1"},"cD":{"av":["1"],"ac":["1"],"av.T":"1"},"eH":{"C":["1"]},"et":{"ac":["1"]},"dr":{"C":["1"],"C.T":"1"},"bx":{"C":["1"],"C.T":"1"},"hg":{"bK":["1"],"cE":["1"],"bZ":["1"],"bG":["1"],"ah":["1"]},"b8":{"C":["2"]},"ex":{"av":["2"],"ac":["2"],"av.T":"2"},"cf":{"b8":["1","1"],"C":["1"],"C.T":"1","b8.T":"1","b8.S":"1"},"aL":{"b8":["1","2"],"C":["2"],"C.T":"2","b8.T":"2","b8.S":"1"},"h9":{"ah":["1"]},"eF":{"av":["2"],"ac":["2"],"av.T":"2"},"c9":{"C":["2"],"C.T":"2"},"cc":{"F":["1","2"],"a3":["1","2"],"F.V":"2","F.K":"1"},"dt":{"cc":["1","2"],"F":["1","2"],"a3":["1","2"],"F.V":"2","F.K":"1"},"h4":{"cc":["1","2"],"F":["1","2"],"a3":["1","2"],"F.V":"2","F.K":"1"},"hb":{"x":["1"],"m":["1"],"m.E":"1"},"hf":{"b1":["1","2"],"F":["1","2"],"a3":["1","2"],"F.V":"2","F.K":"1"},"cd":{"cw":["1"],"bs":["1"],"x":["1"],"m":["1"]},"d3":{"m":["1"],"m.E":"1"},"y":{"t":["1"],"x":["1"],"m":["1"]},"F":{"a3":["1","2"]},"fu":{"a3":["1","2"]},"dh":{"fu":["1","2"],"kz":["1","2"],"a3":["1","2"]},"fs":{"X":["1"],"x":["1"],"m":["1"],"X.E":"1","m.E":"1"},"cw":{"bs":["1"],"x":["1"],"m":["1"]},"hs":{"cw":["1"],"bs":["1"],"x":["1"],"m":["1"]},"dp":{"ah":["1"]},"ez":{"ah":["j"]},"k3":{"F":["j","@"],"a3":["j","@"],"F.V":"@","F.K":"j"},"k4":{"X":["j"],"x":["j"],"m":["j"],"X.E":"j","m.E":"j"},"hR":{"cZ":[]},"ky":{"af":["j","t<a>"]},"hT":{"af":["j","t<a>"],"af.T":"t<a>"},"kx":{"af":["t<a>","j"]},"hS":{"af":["t<a>","j"],"af.T":"j"},"hX":{"af":["t<a>","j"],"af.T":"j"},"fq":{"V":[]},"iA":{"V":[]},"iC":{"af":["k?","j"],"af.T":"j"},"iB":{"af":["j","k?"],"af.T":"k?"},"iD":{"cZ":[]},"iF":{"af":["j","t<a>"],"af.T":"t<a>"},"iE":{"af":["t<a>","j"],"af.T":"j"},"jz":{"cZ":[]},"jB":{"af":["j","t<a>"],"af.T":"t<a>"},"jA":{"af":["t<a>","j"],"af.T":"j"},"wn":{"a7":["wn"]},"bS":{"a7":["bS"]},"Y":{"a7":["bP"]},"bT":{"a7":["bT"]},"a":{"a7":["bP"]},"t":{"x":["1"],"m":["1"]},"bP":{"a7":["bP"]},"j_":{"d4":[]},"bs":{"x":["1"],"m":["1"]},"j":{"a7":["j"]},"az":{"a7":["wn"]},"hU":{"V":[]},"c3":{"V":[]},"a1":{"V":[]},"e4":{"V":[]},"fl":{"V":[]},"fR":{"V":[]},"jr":{"V":[]},"aW":{"V":[]},"i9":{"V":[]},"iT":{"V":[]},"fI":{"V":[]},"jW":{"J":[]},"aT":{"J":[]},"iv":{"J":[],"V":[]},"ku":{"aj":[]},"hC":{"jx":[]},"bh":{"jx":[]},"jT":{"jx":[]},"iR":{"J":[]},"S":{"a3":["2","3"]},"db":{"eJ":["1","bs<1>"],"eJ.E":"1"},"cv":{"J":[]},"hY":{"lH":[]},"i2":{"lH":[]},"cQ":{"C":["t<a>"],"C.T":"t<a>"},"bQ":{"J":[]},"jl":{"cz":[]},"f0":{"S":["j","j","1"],"a3":["j","1"],"S.K":"j","S.V":"1","S.C":"j"},"cq":{"a7":["cq"]},"iV":{"J":[]},"de":{"J":[]},"f7":{"J":[]},"e2":{"J":[]},"d0":{"dU":[]},"bc":{"I":[]},"dL":{"J":[]},"hl":{"cb":[]},"en":{"cb":[]},"h7":{"cb":[]},"ft":{"b6":[],"ar":[]},"dR":{"ar":[]},"fS":{"b6":[],"ar":[]},"ff":{"b6":[],"ar":[]},"dM":{"ar":[]},"fb":{"b6":[],"ar":[]},"f2":{"b6":[],"ar":[]},"fj":{"b6":[],"ar":[]},"fQ":{"b6":[],"ar":[]},"em":{"ah":["t<a>"]},"cu":{"aR":[]},"dO":{"aR":[]},"fU":{"aR":[]},"fP":{"aR":[]},"fi":{"aR":[]},"f3":{"aR":[]},"e5":{"lH":[]},"fY":{"bN":[]},"hr":{"bN":[]},"h6":{"bN":[]},"h3":{"bN":[]},"i6":{"J":[]},"iq":{"bt":[],"a7":["bt"]},"ew":{"c1":[],"a7":["jb"]},"bt":{"a7":["bt"]},"ja":{"bt":[],"a7":["bt"]},"jb":{"a7":["jb"]},"jc":{"a7":["jb"]},"jd":{"J":[]},"e8":{"aT":[],"J":[]},"e9":{"a7":["jb"]},"c1":{"a7":["jb"]},"ea":{"cx":[]},"jj":{"cx":[]},"ji":{"cx":[]},"dc":{"J":[]},"ed":{"cV":[]},"is":{"aB":[]},"k0":{"fW":[],"aO":[]},"bF":{"y":["aV"],"t":["aV"],"x":["aV"],"m":["aV"],"y.E":"aV"},"aV":{"ju":["j","@"],"F":["j","@"],"a3":["j","@"],"F.V":"@","F.K":"j"},"c5":{"J":[]},"i0":{"aB":[]},"i_":{"fW":[],"aO":[]},"dl":{"aG":["dl"],"aG.E":"dl"},"ei":{"y":["cA"],"t":["cA"],"x":["cA"],"m":["cA"],"y.E":"cA"},"eY":{"C":["1"],"C.T":"1"},"cn":{"aB":[]},"aD":{"aG":["aD"]},"k1":{"fW":[],"aO":[]},"ha":{"aD":[],"aG":["aD"],"aG.E":"aD"},"h5":{"aD":[],"aG":["aD"],"aG.E":"aD"},"er":{"aD":[],"aG":["aD"],"aG.E":"aD"},"eL":{"aD":[],"aG":["aD"],"aG.E":"aD"},"e7":{"aB":[]},"kq":{"fW":[],"aO":[]},"f1":{"J":[]},"j1":{"ww":[]},"cl":{"y":["k?"],"t":["k?"],"x":["k?"],"m":["k?"],"y.E":"k?"},"bm":{"J":[]},"d8":{"J":[]},"eo":{"wt":[]},"iH":{"V":[]},"jf":{"aJ":[],"aA":[]},"jg":{"aJ":[],"aA":[]},"bB":{"J":[]},"jv":{"aA":[]},"fE":{"aA":[]},"fF":{"aJ":[],"aA":[]},"aJ":{"aA":[]},"je":{"aJ":[],"aA":[]},"ce":{"aA":[]},"jC":{"vu":[],"aJ":[],"aA":[]},"hW":{"cB":[]},"jn":{"aT":[],"J":[]},"bd":{"ef":["a"],"y":["a"],"t":["a"],"x":["a"],"m":["a"],"y.E":"a"},"ef":{"y":["1"],"t":["1"],"x":["1"],"m":["1"]},"k2":{"ef":["a"],"y":["a"],"t":["a"],"x":["a"],"m":["a"]},"eu":{"C":["1"],"C.T":"1"},"ev":{"ac":["1"]},"nB":{"t":["a"],"x":["a"],"m":["a"]},"be":{"t":["a"],"x":["a"],"m":["a"]},"pB":{"t":["a"],"x":["a"],"m":["a"]},"nz":{"t":["a"],"x":["a"],"m":["a"]},"pz":{"t":["a"],"x":["a"],"m":["a"]},"nA":{"t":["a"],"x":["a"],"m":["a"]},"pA":{"t":["a"],"x":["a"],"m":["a"]},"mV":{"t":["Y"],"x":["Y"],"m":["Y"]},"mW":{"t":["Y"],"x":["Y"],"m":["Y"]},"vu":{"aJ":[],"aA":[]}}'))
A.Ce(v.typeUniverse,JSON.parse('{"ek":1,"j7":1,"ih":1,"iQ":1,"fh":1,"jt":1,"eg":1,"hF":2,"f5":1,"d2":1,"b3":1,"e0":1,"ah":1,"kv":1,"e1":2,"fK":1,"jk":2,"kw":1,"jL":1,"fZ":1,"ks":1,"jU":1,"bv":1,"eD":1,"bO":1,"h9":1,"kr":2,"hs":1,"hB":2,"dp":2,"i7":1,"i8":2,"hv":1,"im":1,"fV":1,"fa":1,"iP":1,"fw":1,"zM":1}'))
var u={S:"\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\u03f6\x00\u0404\u03f4 \u03f4\u03f6\u01f6\u01f6\u03f6\u03fc\u01f4\u03ff\u03ff\u0584\u03ff\u03ff\u03ff\u03ff\u03ff\u03ff\u03ff\u03ff\u03ff\u03ff\u05d4\u01f4\x00\u01f4\x00\u0504\u05c4\u03ff\u03ff\u03ff\u03ff\u03ff\u03ff\u03ff\u03ff\u03ff\u03ff\u03ff\u03ff\u03ff\u03ff\u03ff\u03ff\u03ff\u03ff\u03ff\u03ff\u03ff\u03ff\u03ff\u03ff\u03ff\u03ff\u0400\x00\u0400\u0200\u03f7\u0200\u03ff\u03ff\u03ff\u03ff\u03ff\u03ff\u03ff\u03ff\u03ff\u03ff\u03ff\u03ff\u03ff\u03ff\u03ff\u03ff\u03ff\u03ff\u03ff\u03ff\u03ff\u03ff\u03ff\u03ff\u03ff\u03ff\u0200\u0200\u0200\u03f7\x00",D:" must not be greater than the number of characters in the file, ",U:"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/",l:"Applying checkpoint is blocked on local mutations, but no uploader is set. The sync client cannot proceed.",t:"Broadcast stream controllers do not support pause callbacks",O:"Cannot change the length of a fixed-length list",A:"Cannot extract a file path from a URI with a fragment component",z:"Cannot extract a file path from a URI with a query component",Q:"Cannot extract a non-Windows file path from a file URI with an authority",c:"Cannot fire new event. Controller is already firing an event",w:"Error handler must accept one Object or one Object and a StackTrace as arguments, and return a value of the returned future's type",B:"SELECT seq FROM main.sqlite_sequence WHERE name = 'ps_crud'",f:"Tried to operate on a released prepared statement",y:"handleError callback must take either an Object (the error), or both an Object (the error) and a StackTrace.",E:"max must be in range 0 < max \u2264 2^32, was "}
var t=(function rtii(){var s=A.ap
return{fM:s("@<@>"),fN:s("bm"),ie:s("zM<k?>"),om:s("eY<w<k?>>"),lo:s("cP"),fW:s("v4"),kj:s("f0<j>"),h6:s("ws"),eg:s("wt"),dF:s("lH()"),V:s("bn"),fw:s("cV"),bP:s("a7<@>"),p6:s("cW"),br:s("cX<v>"),kn:s("cX<k?>"),A:s("cX<~>"),hM:s("ck"),em:s("dP"),kS:s("ww"),lp:s("id"),O:s("x<@>"),C:s("V"),L:s("J"),eZ:s("io"),pk:s("mV"),kI:s("mW"),lW:s("aT"),gY:s("EG"),nW:s("n<v>"),mj:s("n<D>"),nK:s("n<+(k?,w<k?>?)>"),fP:s("n<bV?>"),cI:s("n<j?>"),jN:s("n<eh?>"),p8:s("n<~>"),cF:s("cn"),m6:s("nz"),bW:s("nA"),g2:s("dU"),jx:s("nB"),mT:s("W"),ks:s("m<ar>"),e7:s("m<@>"),en:s("w<n<@>>"),M:s("w<n<~>>"),kG:s("w<v>"),dO:s("w<t<k?>>"),hf:s("w<k>"),fU:s("w<+controller,sync(bZ<b7>,G)>"),lw:s("w<+controller,sync(bZ<~>,G)>"),kC:s("w<+(cy,j)>"),iE:s("w<+(j,k?)>"),bN:s("w<+name,parameters(j,j)>"),cH:s("w<+hasSynced,lastSyncedAt,priority(G?,bS?,a)>"),lE:s("w<ed>"),a6:s("w<ac<I>>"),bO:s("w<ac<~>>"),fu:s("w<C<aR>>"),i3:s("w<C<~>>"),s:s("w<j>"),az:s("w<eo>"),ba:s("w<ep>"),dB:s("w<bM<@>>"),g7:s("w<aP>"),dg:s("w<bw>"),o6:s("w<k8>"),jI:s("w<dx>"),gk:s("w<Y>"),dG:s("w<@>"),t:s("w<a>"),b9:s("w<a2?>"),c:s("w<k?>"),mf:s("w<j?>"),iy:s("aE<@>"),v:s("dV"),m:s("v"),bJ:s("aN"),g:s("b_"),dX:s("b0<@>"),d9:s("ag"),kk:s("d3<dl>"),p3:s("d3<aD>"),mu:s("t<w<k?>>"),ip:s("t<v>"),eL:s("t<+name,parameters(j,j)>"),k:s("t<j>"),j:s("t<@>"),f4:s("t<a>"),ia:s("t<k?>"),fi:s("t<j?>"),ag:s("dX"),W:s("dY"),gc:s("K<j,j>"),lx:s("K<j,+atLast,priority,sinceLast,targetCount(a,a,a,a)>"),ea:s("a3<j,@>"),dV:s("a3<j,a>"),av:s("a3<@,@>"),f:s("a3<j,k?>"),iZ:s("a8<j,@>"),eK:s("a8<+(j,k?),j>"),jC:s("EK"),a:s("bE"),dQ:s("cs"),aj:s("b5"),Z:s("d5"),Y:s("b6"),bC:s("fB<n<~>>"),P:s("D"),K:s("k"),lZ:s("EN"),aK:s("+()"),U:s("+immediateRestart(G)"),ja:s("+(v,dN)"),iS:s("+(v,D)"),lg:s("+(D,D)"),k0:s("+(k,D)"),cU:s("+(cy,j)"),E:s("+name,parameters(j,j)"),l4:s("+(ad,k)"),mk:s("+(G,v)"),kO:s("+basicSupport,supportsReadWriteUnsafe(G,G)"),mt:s("+(v?,v)"),jc:s("+(bE?,w<k?>?)"),iu:s("+(k?,w<k?>?)"),ii:s("+autocommit,lastInsertRowid,result(G,a,bF)"),cV:s("+atLast,priority,sinceLast,targetCount(a,a,a,a)"),lu:s("j_"),b:s("e6"),G:s("bF"),hF:s("da<j>"),oy:s("aV"),g_:s("e7"),hq:s("bt"),ol:s("c1"),e1:s("b7"),l:s("aj"),ao:s("bG<I>"),a9:s("fJ<bN>"),ha:s("ac<b7>"),ey:s("ac<~>"),ir:s("C<bN>"),n:s("cz"),N:s("j"),of:s("Z"),o:s("aR"),jM:s("de"),mO:s("ee"),k4:s("aK"),aJ:s("a_"),do:s("c3"),i7:s("pz"),mC:s("pA"),oR:s("bd"),nn:s("pB"),p:s("be"),cx:s("dg"),ph:s("dh<j,j>"),d:s("I"),R:s("jx"),e6:s("aB"),j2:s("fW"),w:s("eh"),m1:s("vu"),lS:s("fX<j>"),u:s("cB"),iq:s("a9<be>"),ho:s("a9<a>"),if:s("a9<ck?>"),mE:s("a9<k?>"),h:s("a9<~>"),it:s("c9<@,j>"),jB:s("c9<@,be>"),hi:s("cb"),fK:s("eq"),Q:s("dq<v>"),hV:s("dr<I>"),d4:s("eu<v>"),nI:s("l<fk>"),fV:s("l<bV>"),a7:s("l<v>"),e:s("l<0&>"),jz:s("l<be>"),B:s("l<G>"),_:s("l<@>"),hy:s("l<a>"),iB:s("l<ck?>"),ny:s("l<k?>"),D:s("l<~>"),nf:s("aP"),mp:s("dt<k?,k?>"),fA:s("eB"),fb:s("bx<t<a>>"),cn:s("bx<bs<j>>"),pp:s("bN"),jy:s("cF<b7,~()>"),af:s("cF<~,G()>"),lU:s("cF<~,~()>"),aP:s("L<fk>"),l6:s("L<bV>"),h1:s("L<v>"),ex:s("L<G>"),gW:s("L<k?>"),F:s("L<~>"),y:s("G"),i:s("Y"),z:s("@"),mq:s("@(k)"),ng:s("@(k,aj)"),S:s("a"),gO:s("ck?"),d_:s("f8?"),gK:s("n<D>?"),m2:s("n<~>?"),b3:s("bV?"),fo:s("dU?"),mU:s("v?"),h9:s("a3<j,k?>?"),aC:s("bE?"),X:s("k?"),J:s("ct?"),x:s("aV?"),mQ:s("ac<bN>?"),T:s("j?"),a_:s("bd?"),he:s("eh?"),dd:s("aP?"),o9:s("G?"),jX:s("Y?"),I:s("a?"),jh:s("bP?"),q:s("bP"),H:s("~"),cj:s("~()"),i6:s("~(k)"),r:s("~(k,aj)")}})();(function constants(){var s=hunkHelpers.makeConstList
B.bi=J.W.prototype
B.c=J.w.prototype
B.b=J.fn.prototype
B.aa=J.dV.prototype
B.ab=J.dW.prototype
B.a=J.co.prototype
B.bj=J.b_.prototype
B.bk=J.ag.prototype
B.af=A.fx.prototype
B.M=A.fz.prototype
B.e=A.d5.prototype
B.ag=J.iW.prototype
B.a_=J.dg.prototype
B.B=new A.bm("Operation was cancelled",null)
B.a0=new A.hS(!1,127)
B.aJ=new A.hT(127)
B.b2=new A.dr(A.ap("dr<t<a>>"))
B.aK=new A.cQ(B.b2)
B.aL=new A.fm(A.Ee(),A.ap("fm<a>"))
B.bY=new A.hX()
B.aM=new A.ld()
B.aN=new A.i6()
B.aO=new A.f2()
B.C=new A.fa()
B.aP=new A.fb()
B.a1=new A.ih()
B.aQ=new A.iv()
B.a2=function getTagFallback(o) {
  var s = Object.prototype.toString.call(o);
  return s.substring(8, s.length - 1);
}
B.aR=function() {
  var toStringFunction = Object.prototype.toString;
  function getTag(o) {
    var s = toStringFunction.call(o);
    return s.substring(8, s.length - 1);
  }
  function getUnknownTag(object, tag) {
    if (/^HTML[A-Z].*Element$/.test(tag)) {
      var name = toStringFunction.call(object);
      if (name == "[object Object]") return null;
      return "HTMLElement";
    }
  }
  function getUnknownTagGenericBrowser(object, tag) {
    if (object instanceof HTMLElement) return "HTMLElement";
    return getUnknownTag(object, tag);
  }
  function prototypeForTag(tag) {
    if (typeof window == "undefined") return null;
    if (typeof window[tag] == "undefined") return null;
    var constructor = window[tag];
    if (typeof constructor != "function") return null;
    return constructor.prototype;
  }
  function discriminator(tag) { return null; }
  var isBrowser = typeof HTMLElement == "function";
  return {
    getTag: getTag,
    getUnknownTag: isBrowser ? getUnknownTagGenericBrowser : getUnknownTag,
    prototypeForTag: prototypeForTag,
    discriminator: discriminator };
}
B.aW=function(getTagFallback) {
  return function(hooks) {
    if (typeof navigator != "object") return hooks;
    var userAgent = navigator.userAgent;
    if (typeof userAgent != "string") return hooks;
    if (userAgent.indexOf("DumpRenderTree") >= 0) return hooks;
    if (userAgent.indexOf("Chrome") >= 0) {
      function confirm(p) {
        return typeof window == "object" && window[p] && window[p].name == p;
      }
      if (confirm("Window") && confirm("HTMLElement")) return hooks;
    }
    hooks.getTag = getTagFallback;
  };
}
B.aS=function(hooks) {
  if (typeof dartExperimentalFixupGetTag != "function") return hooks;
  hooks.getTag = dartExperimentalFixupGetTag(hooks.getTag);
}
B.aV=function(hooks) {
  if (typeof navigator != "object") return hooks;
  var userAgent = navigator.userAgent;
  if (typeof userAgent != "string") return hooks;
  if (userAgent.indexOf("Firefox") == -1) return hooks;
  var getTag = hooks.getTag;
  var quickMap = {
    "BeforeUnloadEvent": "Event",
    "DataTransfer": "Clipboard",
    "GeoGeolocation": "Geolocation",
    "Location": "!Location",
    "WorkerMessageEvent": "MessageEvent",
    "XMLDocument": "!Document"};
  function getTagFirefox(o) {
    var tag = getTag(o);
    return quickMap[tag] || tag;
  }
  hooks.getTag = getTagFirefox;
}
B.aU=function(hooks) {
  if (typeof navigator != "object") return hooks;
  var userAgent = navigator.userAgent;
  if (typeof userAgent != "string") return hooks;
  if (userAgent.indexOf("Trident/") == -1) return hooks;
  var getTag = hooks.getTag;
  var quickMap = {
    "BeforeUnloadEvent": "Event",
    "DataTransfer": "Clipboard",
    "HTMLDDElement": "HTMLElement",
    "HTMLDTElement": "HTMLElement",
    "HTMLPhraseElement": "HTMLElement",
    "Position": "Geoposition"
  };
  function getTagIE(o) {
    var tag = getTag(o);
    var newTag = quickMap[tag];
    if (newTag) return newTag;
    if (tag == "Object") {
      if (window.DataView && (o instanceof window.DataView)) return "DataView";
    }
    return tag;
  }
  function prototypeForTagIE(tag) {
    var constructor = window[tag];
    if (constructor == null) return null;
    return constructor.prototype;
  }
  hooks.getTag = getTagIE;
  hooks.prototypeForTag = prototypeForTagIE;
}
B.aT=function(hooks) {
  var getTag = hooks.getTag;
  var prototypeForTag = hooks.prototypeForTag;
  function getTagFixed(o) {
    var tag = getTag(o);
    if (tag == "Document") {
      if (!!o.xmlVersion) return "!Document";
      return "!HTMLDocument";
    }
    return tag;
  }
  function prototypeForTagFixed(tag) {
    if (tag == "Document") return null;
    return prototypeForTag(tag);
  }
  hooks.getTag = getTagFixed;
  hooks.prototypeForTag = prototypeForTagFixed;
}
B.a3=function(hooks) { return hooks; }

B.h=new A.nH()
B.k=new A.iD()
B.r=new A.fr()
B.aX=new A.nI()
B.x=new A.iI(A.ap("iI<j,@>"))
B.aY=new A.iT()
B.d=new A.ou()
B.b_=new A.db(A.ap("db<j>"))
B.aZ=new A.db(A.ap("db<+name,parameters(j,j)>"))
B.b0=new A.fP()
B.a4=new A.fU()
B.l=new A.jz()
B.o=new A.jB()
B.b1=new A.rm()
B.y=new A.ro()
B.a5=new A.h7()
B.b3=new A.rY()
B.D=new A.hl()
B.t=new A.ku()
B.b4=new A.tK()
B.b5=new A.dL("The PowerSync service does not support checkpoint requests. Update to PowerSync service version 1.24.0 or later to use this API.")
B.z=new A.dL("Cannot request checkpoints, sync client is disconnected")
B.b6=new A.dL("Connected with legacy checkpoint mode, cannot request checkpoints")
B.b7=new A.dO(0,"established")
B.b8=new A.dO(1,"end")
B.E=new A.bR(3,"updateSubscriptionManagement")
B.F=new A.bR(4,"notifyUpdates")
B.a6=new A.bT(0)
B.G=new A.bT(1e4)
B.u=new A.bT(5e6)
B.H=new A.cm("x",1,"opfsExternalLocks")
B.a7=new A.cm("y",2,"opfsExternalLocksWorkaround")
B.a8=new A.dS("/database",0,"database")
B.a9=new A.dS("/database-journal",1,"journal")
B.bl=new A.iB(null)
B.bm=new A.iC(null)
B.ac=new A.iE(!1,255)
B.bn=new A.iF(255)
B.p=new A.cq("FINE",500)
B.m=new A.cq("INFO",800)
B.i=new A.cq("WARNING",900)
B.O=new A.ad(0,"ping")
B.ap=new A.ad(1,"startSynchronization")
B.az=new A.ad(2,"updateSubscriptions")
B.aA=new A.ad(3,"abortSynchronization")
B.Q=new A.ad(4,"requestEndpoint")
B.R=new A.ad(5,"uploadCrud")
B.aB=new A.ad(6,"customCheckpointRequest")
B.aC=new A.ad(7,"requestCheckpoint")
B.S=new A.ad(8,"invalidCredentialsCallback")
B.T=new A.ad(9,"credentialsCallback")
B.P=new A.ad(10,"prefetchCredentialsCallback")
B.aq=new A.ad(11,"abortRequest")
B.ar=new A.ad(12,"notifySyncStatus")
B.as=new A.ad(13,"handleDiagnostics")
B.at=new A.ad(14,"logEvent")
B.au=new A.ad(15,"sendHttpRequest")
B.av=new A.ad(16,"abortHttpRequest")
B.aw=new A.ad(17,"readResponseChunk")
B.ax=new A.ad(18,"okResponse")
B.ay=new A.ad(19,"errorResponse")
B.bo=s([B.O,B.ap,B.az,B.aA,B.Q,B.R,B.aB,B.aC,B.S,B.T,B.P,B.aq,B.ar,B.as,B.at,B.au,B.av,B.aw,B.ax,B.ay],A.ap("w<ad>"))
B.bp=s([239,191,189],t.t)
B.w=new A.bu(0,"unknown")
B.U=new A.bu(1,"integer")
B.V=new A.bu(2,"bigInt")
B.W=new A.bu(3,"float")
B.X=new A.bu(4,"text")
B.Y=new A.bu(5,"blob")
B.Z=new A.bu(6,"$null")
B.aD=new A.bu(7,"boolean")
B.I=s([B.w,B.U,B.V,B.W,B.X,B.Y,B.Z,B.aD],A.ap("w<bu>"))
B.bq=s([65533],t.t)
B.bg=new A.fg(0,"database")
B.bh=new A.fg(1,"journal")
B.ad=s([B.bg,B.bh],A.ap("w<fg>"))
B.bf=new A.cm("s",0,"opfsShared")
B.bd=new A.cm("i",3,"indexedDb")
B.be=new A.cm("m",4,"inMemory")
B.br=s([B.bf,B.H,B.a7,B.bd,B.be],A.ap("w<cm>"))
B.b9=new A.bR(0,"ok")
B.ba=new A.bR(1,"getAutoCommit")
B.bb=new A.bR(2,"executeBatch")
B.bc=new A.bR(5,"installBroadcastUpdates")
B.ae=s([B.b9,B.ba,B.bb,B.E,B.F,B.bc],A.ap("w<bR>"))
B.aj=new A.eb(0,"insert")
B.ak=new A.eb(1,"update")
B.al=new A.eb(2,"delete")
B.bs=s([B.aj,B.ak,B.al],A.ap("w<eb>"))
B.J=s([],t.s)
B.bu=s([],t.t)
B.n=s([],t.c)
B.bt=s([],t.bN)
B.bv=s([B.a8,B.a9],A.ap("w<dS>"))
B.am=new A.cy(0,"opfs")
B.an=new A.cy(1,"indexedDb")
B.bD=new A.cy(2,"inMemory")
B.bw=s([B.am,B.an,B.bD],A.ap("w<cy>"))
B.bA={"iso_8859-1:1987":0,"iso-ir-100":1,"iso_8859-1":2,"iso-8859-1":3,latin1:4,l1:5,ibm819:6,cp819:7,csisolatin1:8,"iso-ir-6":9,"ansi_x3.4-1968":10,"ansi_x3.4-1986":11,"iso_646.irv:1991":12,"iso646-us":13,"us-ascii":14,us:15,ibm367:16,cp367:17,csascii:18,ascii:19,csutf8:20,"utf-8":21}
B.j=new A.hR()
B.bx=new A.bo(B.bA,[B.k,B.k,B.k,B.k,B.k,B.k,B.k,B.k,B.k,B.j,B.j,B.j,B.j,B.j,B.j,B.j,B.j,B.j,B.j,B.j,B.l,B.l],A.ap("bo<j,cZ>"))
B.A={}
B.L=new A.bo(B.A,[],A.ap("bo<j,j>"))
B.by=new A.bo(B.A,[],A.ap("bo<j,a>"))
B.K=new A.bo(B.A,[],A.ap("bo<j,@>"))
B.q=new A.fw(11,"simpleSuccessResponse")
B.bz=new A.fw(13,"rowsResponse")
B.bZ=new A.nZ(2,"readWriteCreate")
B.ah=new A.hn(!1)
B.ai=new A.N(null,null)
B.N=new A.ho(!1,!1)
B.bB=new A.hq("BEGIN IMMEDIATE","COMMIT","ROLLBACK")
B.bC=new A.f6(B.A,0,A.ap("f6<j>"))
B.bE=new A.fM("_clientToken@package:http/src/client.dart")
B.v=new A.fM("reset")
B.ao=new A.pb(0,"rust")
B.bF=A.bl("cP")
B.bG=A.bl("v4")
B.bH=A.bl("mV")
B.bI=A.bl("mW")
B.bJ=A.bl("nz")
B.bK=A.bl("nA")
B.bL=A.bl("nB")
B.bM=A.bl("v")
B.bN=A.bl("k")
B.bO=A.bl("pz")
B.bP=A.bl("pA")
B.bQ=A.bl("pB")
B.bR=A.bl("be")
B.bS=new A.fT("DELETE",2,"delete")
B.bT=new A.fT("PATCH",1,"patch")
B.bU=new A.fT("PUT",0,"put")
B.aE=new A.jA(!1)
B.bV=new A.c5(14)
B.bW=new A.c5(522)
B.bX=new A.c5(778)
B.f=new A.c8(null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null)
B.aF=new A.eG("canceled")
B.aG=new A.eG("dormant")
B.aH=new A.eG("listening")
B.aI=new A.eG("paused")})();(function staticFields(){$.t_=null
$.dB=A.u([],t.hf)
$.Df=null
$.wX=null
$.wq=null
$.wp=null
$.yE=null
$.yx=null
$.yN=null
$.uo=null
$.uA=null
$.w5=null
$.tc=A.u([],A.ap("w<t<k>?>"))
$.eP=null
$.hH=null
$.hI=null
$.vW=!1
$.o=B.f
$.xt=null
$.xu=null
$.xv=null
$.xw=null
$.vx=A.r_("_lastQuoRemDigits")
$.vy=A.r_("_lastQuoRemUsed")
$.h1=A.r_("_lastRemUsed")
$.vz=A.r_("_lastRem_nsh")
$.xo=""
$.xp=null
$.eO=0
$.eM=A.T(t.N,t.S)
$.wO=0
$.AB=A.T(t.N,t.W)
$.yc=null
$.tX=null})();(function lazyInitializers(){var s=hunkHelpers.lazyFinal,r=hunkHelpers.lazy
s($,"EE","z_",()=>A.us("_$dart_dartClosure"))
s($,"ED","dH",()=>A.us("_$dart_dartClosure_dartJSInterop"))
s($,"FB","zw",()=>B.f.oC(new A.uN(),t.p8))
s($,"Fv","zt",()=>A.u([new J.iw()],A.ap("w<fD>")))
s($,"EV","z3",()=>A.c4(A.py({
toString:function(){return"$receiver$"}})))
s($,"EW","z4",()=>A.c4(A.py({$method$:null,
toString:function(){return"$receiver$"}})))
s($,"EX","z5",()=>A.c4(A.py(null)))
s($,"EY","z6",()=>A.c4(function(){var $argumentsExpr$="$arguments$"
try{null.$method$($argumentsExpr$)}catch(q){return q.message}}()))
s($,"F0","z9",()=>A.c4(A.py(void 0)))
s($,"F1","za",()=>A.c4(function(){var $argumentsExpr$="$arguments$"
try{(void 0).$method$($argumentsExpr$)}catch(q){return q.message}}()))
s($,"F_","z8",()=>A.c4(A.xl(null)))
s($,"EZ","z7",()=>A.c4(function(){try{null.$method$}catch(q){return q.message}}()))
s($,"F3","zc",()=>A.c4(A.xl(void 0)))
s($,"F2","zb",()=>A.c4(function(){try{(void 0).$method$}catch(q){return q.message}}()))
s($,"F5","wb",()=>A.Br())
s($,"EI","cM",()=>$.zw())
s($,"EH","z0",()=>A.BK(!1,B.f,t.y))
s($,"Fu","zs",()=>A.Bo())
s($,"Ff","zi",()=>A.AF(4096))
s($,"Fd","zg",()=>new A.tH().$0())
s($,"Fe","zh",()=>new A.tG().$0())
s($,"F6","zd",()=>A.AD(A.vS(A.u([-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-1,-2,-2,-2,-2,-2,62,-2,62,-2,63,52,53,54,55,56,57,58,59,60,61,-2,-2,-2,-1,-2,-2,-2,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,-2,-2,-2,-2,63,-2,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,-2,-2,-2,-2,-2],t.t))))
s($,"Fb","ci",()=>A.qR(0))
s($,"Fa","kU",()=>A.qR(1))
s($,"F8","wd",()=>$.kU().by(0))
s($,"F7","wc",()=>A.qR(1e4))
r($,"F9","ze",()=>A.at("^\\s*([+-]?)((0x[a-f0-9]+)|(\\d+)|([a-z0-9]+))\\s*$",!1))
s($,"Fc","zf",()=>typeof FinalizationRegistry=="function"?FinalizationRegistry:null)
s($,"Fi","eW",()=>A.kP(B.bN))
r($,"Fp","kV",()=>new A.u2().$0())
r($,"Fm","zn",()=>new A.u0().$0())
s($,"Fl","zm",()=>Symbol("jsBoxedDartObjectProperty"))
s($,"EM","z1",()=>{var q=new A.rZ(A.AC(8))
q.kQ()
return q})
s($,"EB","yZ",()=>A.at("^[\\w!#%&'*+\\-.^`|~]+$",!0))
s($,"Fh","zj",()=>A.at('["\\x00-\\x1F\\x7F]',!0))
s($,"FC","zx",()=>A.at('[^()<>@,;:"\\\\/[\\]?={} \\t\\x00-\\x1F\\x7F]+',!0))
s($,"Fo","zo",()=>A.at("(?:\\r\\n)?[ \\t]+",!0))
s($,"Fr","zq",()=>A.at('"(?:[^"\\x00-\\x1F\\x7F\\\\]|\\\\.)*"',!0))
s($,"Fq","zp",()=>A.at("\\\\(.)",!0))
s($,"FA","zv",()=>A.at('[()<>@,;:"\\\\/\\[\\]?={} \\t\\x00-\\x1F\\x7F]',!0))
s($,"FD","zy",()=>A.at("(?:"+$.zo().a+")*",!0))
s($,"EJ","v1",()=>A.vk(""))
s($,"Fy","wf",()=>new A.lY($.wa()))
s($,"ES","z2",()=>new A.o0(A.at("/",!0),A.at("[^/]$",!0),A.at("^/",!0)))
s($,"EU","kT",()=>new A.qe(A.at("[/\\\\]",!0),A.at("[^/\\\\]$",!0),A.at("^(\\\\\\\\[^\\\\]+\\\\[^\\\\/]+|[a-zA-Z]:[/\\\\])",!0),A.at("^[/\\\\](?![/\\\\])",!0)))
s($,"ET","hL",()=>new A.pL(A.at("/",!0),A.at("(^[a-zA-Z][-+.a-zA-Z\\d]*://|[^/])$",!0),A.at("[a-zA-Z][-+.a-zA-Z\\d]*://[^/]*",!0),A.at("^/",!0)))
s($,"ER","wa",()=>A.B6())
s($,"Fx","we",()=>A.D8())
s($,"Fn","cN",()=>$.we())
s($,"Fk","zl",()=>A.wJ(A.yF(),"SharedWorkerGlobalScope"))
s($,"Fj","zk",()=>A.wJ(A.yF(),"DedicatedWorkerGlobalScope"))
s($,"EC","kS",()=>$.z1())
s($,"Fw","zu",()=>A.Az(A.u([A.vq("files"),A.vq("blocks")],t.s)))
s($,"EF","v0",()=>{var q,p,o=A.T(t.N,A.ap("dS"))
for(q=0;q<2;++q){p=B.bv[q]
o.m(0,p.c,p)}return o})
s($,"Fs","zr",()=>A.AO())
r($,"F4","hM",()=>{var q="navigator"
return A.Ar(A.As(A.uu(A.yQ(),q),A.vq("locks")))?A.uu(A.uu(A.yQ(),q),"locks"):null})})();(function nativeSupport(){!function(){var s=function(a){var m={}
m[a]=1
return Object.keys(hunkHelpers.convertToFastObject(m))[0]}
v.getIsolateTag=function(a){return s("___dart_"+a+v.isolateTag)}
var r="___dart_isolate_tags_"
var q=Object[r]||(Object[r]=Object.create(null))
var p="_ZxYxX"
for(var o=0;;o++){var n=s(p+"_"+o+"_")
if(!(n in q)){q[n]=1
v.isolateTag=n
break}}v.dispatchPropertyName=v.getIsolateTag("dispatch_record")}()
hunkHelpers.setOrUpdateInterceptorsByTag({SharedArrayBuffer:A.e_,ArrayBuffer:A.bE,ArrayBufferView:A.fy,DataView:A.fx,Float32Array:A.iJ,Float64Array:A.iK,Int16Array:A.iL,Int32Array:A.iM,Int8Array:A.iN,Uint16Array:A.iO,Uint32Array:A.fz,Uint8ClampedArray:A.fA,CanvasPixelArray:A.fA,Uint8Array:A.d5})
hunkHelpers.setOrUpdateLeafTags({SharedArrayBuffer:true,ArrayBuffer:true,ArrayBufferView:false,DataView:true,Float32Array:true,Float64Array:true,Int16Array:true,Int32Array:true,Int8Array:true,Uint16Array:true,Uint32Array:true,Uint8ClampedArray:true,CanvasPixelArray:true,Uint8Array:false})
A.e0.$nativeSuperclassTag="ArrayBufferView"
A.hh.$nativeSuperclassTag="ArrayBufferView"
A.hi.$nativeSuperclassTag="ArrayBufferView"
A.cs.$nativeSuperclassTag="ArrayBufferView"
A.hj.$nativeSuperclassTag="ArrayBufferView"
A.hk.$nativeSuperclassTag="ArrayBufferView"
A.b5.$nativeSuperclassTag="ArrayBufferView"})()
Function.prototype.$0=function(){return this()}
Function.prototype.$1=function(a){return this(a)}
Function.prototype.$4=function(a,b,c,d){return this(a,b,c,d)}
Function.prototype.$2=function(a,b){return this(a,b)}
Function.prototype.$3=function(a,b,c){return this(a,b,c)}
Function.prototype.$1$4=function(a,b,c,d){return this(a,b,c,d)}
Function.prototype.$2$5=function(a,b,c,d,e){return this(a,b,c,d,e)}
Function.prototype.$3$6=function(a,b,c,d,e,f){return this(a,b,c,d,e,f)}
Function.prototype.$3$4=function(a,b,c,d){return this(a,b,c,d)}
Function.prototype.$2$4=function(a,b,c,d){return this(a,b,c,d)}
Function.prototype.$5=function(a,b,c,d,e){return this(a,b,c,d,e)}
Function.prototype.$2$0=function(){return this()}
Function.prototype.$1$1=function(a){return this(a)}
Function.prototype.$1$0=function(){return this()}
Function.prototype.$2$1=function(a){return this(a)}
Function.prototype.$1$2=function(a,b){return this(a,b)}
convertAllToFastObject(w)
convertToFastObject($);(function(a){if(typeof document==="undefined"){a(null)
return}if(typeof document.currentScript!="undefined"){a(document.currentScript)
return}var s=document.scripts
function onLoad(b){for(var q=0;q<s.length;++q){s[q].removeEventListener("load",onLoad,false)}a(b.target)}for(var r=0;r<s.length;++r){s[r].addEventListener("load",onLoad,false)}})(function(a){v.currentScript=a
var s=A.Ec
if(typeof dartMainRunner==="function"){dartMainRunner(s,[])}else{s([])}})})()
//# sourceMappingURL=powersync_db.worker.js.map
