'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {".git/COMMIT_EDITMSG": "ef1a27de28ed85f232e264ae2c4d80a8",
".git/config": "616afacc174bdbf3432873d663eaa315",
".git/description": "a0a7c3fff21f2aea3cfa1d0316dd816c",
".git/HEAD": "5ab7a4355e4c959b0c5c008f202f51ec",
".git/hooks/applypatch-msg.sample": "ce562e08d8098926a3862fc6e7905199",
".git/hooks/commit-msg.sample": "579a3c1e12a1e74a98169175fb913012",
".git/hooks/fsmonitor-watchman.sample": "a0b2633a2c8e97501610bd3f73da66fc",
".git/hooks/post-update.sample": "2b7ea5cee3c49ff53d41e00785eb974c",
".git/hooks/pre-applypatch.sample": "054f9ffb8bfe04a599751cc757226dda",
".git/hooks/pre-commit.sample": "5029bfab85b1c39281aa9697379ea444",
".git/hooks/pre-merge-commit.sample": "39cb268e2a85d436b9eb6f47614c3cbc",
".git/hooks/pre-push.sample": "2c642152299a94e05ea26eae11993b13",
".git/hooks/pre-rebase.sample": "56e45f2bcbc8226d2b4200f7c46371bf",
".git/hooks/pre-receive.sample": "2ad18ec82c20af7b5926ed9cea6aeedd",
".git/hooks/prepare-commit-msg.sample": "2b5c047bdb474555e1787db32b2d2fc5",
".git/hooks/push-to-checkout.sample": "c7ab00c7784efeadad3ae9b228d4b4db",
".git/hooks/sendemail-validate.sample": "4d67df3a8d5c98cb8565c07e42be0b04",
".git/hooks/update.sample": "647ae13c682f7827c22f5fc08a03674e",
".git/index": "b92f1c0bbd0f7faa4f2d5703753943d3",
".git/info/exclude": "036208b4a1ab4a235d75c181e685e5a3",
".git/logs/HEAD": "72ae10a4be22b1d2a5c05d763dd79623",
".git/logs/refs/heads/gh-pages": "72ae10a4be22b1d2a5c05d763dd79623",
".git/logs/refs/remotes/origin/gh-pages": "c26c382424c2bb748b12fa8d79e049c6",
".git/objects/02/1d4f3579879a4ac147edbbd8ac2d91e2bc7323": "9e9721befbee4797263ad5370cd904ff",
".git/objects/04/b8051daaf35094b3a5ca7d2fd4f72a62686717": "5a1a003b649e4304b8cf079e1813df6a",
".git/objects/08/cef72ecd422c9a6191f8cae9ed5fd9862fbf89": "6ebc4b35a246550a8ca25427c67d73d8",
".git/objects/0e/6fe19311e6acc88425ff15e689d971fee5b517": "c37d7a2793a64a0bcc1ac4895ae4f077",
".git/objects/1a/31e0302a40ff3e2b626e8a9c880ecdb9d560ef": "6e6af19606fe13061736b016ad53ca33",
".git/objects/1f/c993bb56031b8c1b9f9afda405cd30f80e0ef9": "77ca7acf7f5a98b0ea459d0afba5c6a3",
".git/objects/20/3a3ff5cc524ede7e585dff54454bd63a1b0f36": "4b23a88a964550066839c18c1b5c461e",
".git/objects/28/898a2d8e31584af0a0e73121b5b8fc4eba7750": "2ef81072de89356ade8003557843cfde",
".git/objects/29/f22f56f0c9903bf90b2a78ef505b36d89a9725": "e85914d97d264694217ae7558d414e81",
".git/objects/2a/84190f016a455e209c685ca7d6c4f17f6b8a6c": "0a792f85c942d593fdc160c904ceb048",
".git/objects/2f/131fe1fd8e60f5d31975aa365f1e12a6be0c94": "1bc34ab1941ee3e995aa25d93fe5f5ef",
".git/objects/40/9f4c96f4d32fa8c540b6d1f69960570b3b7312": "d364a83bfe14ba199a3fe41f3d97cd51",
".git/objects/42/e76acc40825e6721d6d4bb29803ffe842e08d3": "13be38f4f1d368e3d22c7242e03459cb",
".git/objects/46/4ab5882a2234c39b1a4dbad5feba0954478155": "2e52a767dc04391de7b4d0beb32e7fc4",
".git/objects/48/e012e3ce7011e23949fa8461c96a9445009600": "61ea176d366191f953d5772afa7d96f9",
".git/objects/4d/bf9da7bcce5387354fe394985b98ebae39df43": "534c022f4a0845274cbd61ff6c9c9c33",
".git/objects/4f/fbe6ec4693664cb4ff395edf3d949bd4607391": "2beb9ca6c799e0ff64e0ad79f9e55e69",
".git/objects/50/3fdbb3edc1e901d96612099be5fe9e6dca6905": "41253ac2cdf6809221d9a927a3f11a06",
".git/objects/65/4c8ec8a90f9a9da891a940b1da5a7b35b404dc": "39fc3569177ce29a64f96a3356117470",
".git/objects/76/de39af57a902aefb256b40a2cd8915a993c389": "29c2fabf0730924ee1f8f0f4e724be3b",
".git/objects/7a/6c1911dddaea52e2dbffc15e45e428ec9a9915": "f1dee6885dc6f71f357a8e825bda0286",
".git/objects/7c/5bece1c02d47de97907a059ecb06a076a71851": "0aa4fbd1c5e2f437a9d665cbf7b8c737",
".git/objects/80/7028c92eefd16d2d2d5061e4d3141872fecc4d": "f346819a1255709674e6d446b01942af",
".git/objects/82/744b3362415b78fbcf6cf3fcee62c5cc3a2eec": "b8ff83e80fc7f8cc1a4b25c20f9fec08",
".git/objects/88/cfd48dff1169879ba46840804b412fe02fefd6": "e42aaae6a4cbfbc9f6326f1fa9e3380c",
".git/objects/8a/aa46ac1ae21512746f852a42ba87e4165dfdd1": "1d8820d345e38b30de033aa4b5a23e7b",
".git/objects/8c/b1a4b1d3c77458013b87bca1c09798a5f20435": "824384b836b7bf17fe3d39e5c558027a",
".git/objects/8f/c93275ffe8c2fbe5d22486618ff98fbf33a8bd": "fe9524f7b5b925c06bd8584148c17b28",
".git/objects/98/0d49437042d93ffa850a60d02cef584a35a85c": "8e18e4c1b6c83800103ff097cc222444",
".git/objects/9b/3ef5f169177a64f91eafe11e52b58c60db3df2": "91d370e4f73d42e0a622f3e44af9e7b1",
".git/objects/9e/3b4630b3b8461ff43c272714e00bb47942263e": "accf36d08c0545fa02199021e5902d52",
".git/objects/ab/5f03754807b43a28f1d74bb83098b7273af47a": "dd011ecf3af6fb2f186f596211225a82",
".git/objects/ad/dfef621d71a594c0c24652b1243cba9f671d4f": "6954463862ea3997bde178bf323511f9",
".git/objects/b2/840752be40f41922a9f14b3787651b97366ae4": "1b141641c018fe5679d9ed0e9209fec6",
".git/objects/b6/b8806f5f9d33389d53c2868e6ea1aca7445229": "b14016efdbcda10804235f3a45562bbf",
".git/objects/b7/49bfef07473333cf1dd31e9eed89862a5d52aa": "36b4020dca303986cad10924774fb5dc",
".git/objects/b9/2a0d854da9a8f73216c4a0ef07a0f0a44e4373": "f62d1eb7f51165e2a6d2ef1921f976f3",
".git/objects/ba/92c18d31df8e34b5aacc8e96ba01c78750946a": "68dde71e5546e9fc6ee46da9fb3419e8",
".git/objects/c3/1e02206538252c3690e9351c1049b39dac953e": "3b4cd847140d9c20269bdcce0849ef82",
".git/objects/c4/016f7d68c0d70816a0c784867168ffa8f419e1": "fdf8b8a8484741e7a3a558ed9d22f21d",
".git/objects/ca/3bba02c77c467ef18cffe2d4c857e003ad6d5d": "316e3d817e75cf7b1fd9b0226c088a43",
".git/objects/d3/5cc05a9817ad5221f98fae61cfee7aac5c0d57": "e4cbe2fb58ead4549d1d8ed709808df7",
".git/objects/d4/3532a2348cc9c26053ddb5802f0e5d4b8abc05": "3dad9b209346b1723bb2cc68e7e42a44",
".git/objects/d5/fc9341cbd6f1b940031050d326920e52d410f6": "56adc51241f1d5dd9b914f842aac4e30",
".git/objects/d6/9c56691fbdb0b7efa65097c7cc1edac12a6d3e": "868ce37a3a78b0606713733248a2f579",
".git/objects/dd/739b55f2c58078ba1bbf3adaa4ccbf9b5ac430": "d0c95f6ce8b5edd04d79f628c00cc6b5",
".git/objects/e0/44fd8374f97232264dc5649d78ecdea69b3cf4": "d652a5bc778064a2561e3fd7d48cff11",
".git/objects/e1/eba01a02974cd30f60063211d908c2b4c75cee": "d719148d66ba35efffab333817f11b76",
".git/objects/e3/e9ee754c75ae07cc3d19f9b8c1e656cc4946a1": "14066365125dcce5aec8eb1454f0d127",
".git/objects/e8/f3bbd8b7e536db9694e9ec4aaaee5c8ce4caa9": "fd2a111424608085edf2aa48b0355646",
".git/objects/eb/9b4d76e525556d5d89141648c724331630325d": "37c0954235cbe27c4d93e74fe9a578ef",
".git/objects/ed/b55d4deb8363b6afa65df71d1f9fd8c7787f22": "886ebb77561ff26a755e09883903891d",
".git/objects/f2/04823a42f2d890f945f70d88b8e2d921c6ae26": "6b47f314ffc35cf6a1ced3208ecc857d",
".git/objects/f5/153f388f21e5f2526404f9bcc23e6216621488": "abe3e9d40c58c2f16aac5ad837591f49",
".git/objects/f9/3058dc3785d11f1cb1074707be6de6d081c512": "4a05b7c8af1d49657cbedcdc3f9244ad",
".git/objects/fe/3b987e61ed346808d9aa023ce3073530ad7426": "dc7db10bf25046b27091222383ede515",
".git/objects/ff/adb85560740efcab0ae13054cdcc1492d23e57": "b86abdc33b8d0351e7741d70c8c31596",
".git/refs/heads/gh-pages": "442aa518a229fd2aeb715e0d4179c901",
".git/refs/remotes/origin/gh-pages": "442aa518a229fd2aeb715e0d4179c901",
"assets/AssetManifest.bin": "e90017c6ca4b38067c06992d5ec79f62",
"assets/AssetManifest.bin.json": "a679b6a2cf195b0916962c95a20eab26",
"assets/AssetManifest.json": "100a91017405f36262adf24e9c200c79",
"assets/assets/images/category1.jpg": "d871d05e6f3c2a8c34a6a6f12eedf986",
"assets/assets/images/category2.jpg": "2e6d7407b0b53099d2047ecae01321c2",
"assets/assets/images/category3.jpg": "fb0cce3f4578fded6fc7ce0597f961a0",
"assets/assets/images/category4.jpg": "d6386e2eb1022fc62f640e7813aa887c",
"assets/assets/images/category5.jpg": "abd56f8bce494adc996cfc3896512181",
"assets/assets/images/DressShirt.jpg": "b85bc1afcfa2225a6b2c33fe1b2ab7a5",
"assets/assets/images/iPhone16.jpg": "7122e6a1598ef0812dcc5b7938e6cf5b",
"assets/assets/images/iPhone16Pro.PNG": "9dc3dec412a2e7af461f7a02f5f49c8a",
"assets/assets/images/iPhone16ProMax.jpg": "1329bacc214a5ee6511389832e5bd7da",
"assets/assets/images/login.jpg": "30fcdeaa92b2ce01587d830a03991c66",
"assets/assets/images/POLO.jpg": "49180bee667637bb521cef39286b9383",
"assets/FontManifest.json": "dc3d03800ccca4601324923c0b1d6d57",
"assets/fonts/MaterialIcons-Regular.otf": "04bf0c64e6a7f724609331fa4256c36f",
"assets/NOTICES": "0c1c1572abeb9cd9c933ded82583d4b4",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "03750ee730585e20c39e264bb911ff4a",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"canvaskit/canvaskit.js": "140ccb7d34d0a55065fbd422b843add6",
"canvaskit/canvaskit.js.symbols": "58832fbed59e00d2190aa295c4d70360",
"canvaskit/canvaskit.wasm": "07b9f5853202304d3b0749d9306573cc",
"canvaskit/chromium/canvaskit.js": "5e27aae346eee469027c80af0751d53d",
"canvaskit/chromium/canvaskit.js.symbols": "193deaca1a1424049326d4a91ad1d88d",
"canvaskit/chromium/canvaskit.wasm": "24c77e750a7fa6d474198905249ff506",
"canvaskit/skwasm.js": "1ef3ea3a0fec4569e5d531da25f34095",
"canvaskit/skwasm.js.symbols": "0088242d10d7e7d6d2649d1fe1bda7c1",
"canvaskit/skwasm.wasm": "264db41426307cfc7fa44b95a7772109",
"canvaskit/skwasm_heavy.js": "413f5b2b2d9345f37de148e2544f584f",
"canvaskit/skwasm_heavy.js.symbols": "3c01ec03b5de6d62c34e17014d1decd3",
"canvaskit/skwasm_heavy.wasm": "8034ad26ba2485dab2fd49bdd786837b",
"favicon.png": "5dcef449791fa27946b3d35ad8803796",
"flutter.js": "888483df48293866f9f41d3d9274a779",
"flutter_bootstrap.js": "cf0481861156e2744f064f0fa89ec40c",
"icons/Icon-192.png": "ac9a721a12bbc803b44f645561ecb1e1",
"icons/Icon-512.png": "96e752610906ba2a93c65f8abe1645f1",
"icons/Icon-maskable-192.png": "c457ef57daa1d16f64b27b786ec2ea3c",
"icons/Icon-maskable-512.png": "301a7604d45b3e739efc881eb04896ea",
"index.html": "81036c095c7303500ae3f8d5f2076340",
"/": "81036c095c7303500ae3f8d5f2076340",
"main.dart.js": "dab9a6229d31a0278fa180a3e9bd8c5e",
"manifest.json": "0030ff64be1c3181710c3014b11018a8",
"version.json": "2b521e10dfa0f067561de489a19d6620"};
// The application shell files that are downloaded before a service worker can
// start.
const CORE = ["main.dart.js",
"index.html",
"flutter_bootstrap.js",
"assets/AssetManifest.bin.json",
"assets/FontManifest.json"];

// During install, the TEMP cache is populated with the application shell files.
self.addEventListener("install", (event) => {
  self.skipWaiting();
  return event.waitUntil(
    caches.open(TEMP).then((cache) => {
      return cache.addAll(
        CORE.map((value) => new Request(value, {'cache': 'reload'})));
    })
  );
});
// During activate, the cache is populated with the temp files downloaded in
// install. If this service worker is upgrading from one with a saved
// MANIFEST, then use this to retain unchanged resource files.
self.addEventListener("activate", function(event) {
  return event.waitUntil(async function() {
    try {
      var contentCache = await caches.open(CACHE_NAME);
      var tempCache = await caches.open(TEMP);
      var manifestCache = await caches.open(MANIFEST);
      var manifest = await manifestCache.match('manifest');
      // When there is no prior manifest, clear the entire cache.
      if (!manifest) {
        await caches.delete(CACHE_NAME);
        contentCache = await caches.open(CACHE_NAME);
        for (var request of await tempCache.keys()) {
          var response = await tempCache.match(request);
          await contentCache.put(request, response);
        }
        await caches.delete(TEMP);
        // Save the manifest to make future upgrades efficient.
        await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
        // Claim client to enable caching on first launch
        self.clients.claim();
        return;
      }
      var oldManifest = await manifest.json();
      var origin = self.location.origin;
      for (var request of await contentCache.keys()) {
        var key = request.url.substring(origin.length + 1);
        if (key == "") {
          key = "/";
        }
        // If a resource from the old manifest is not in the new cache, or if
        // the MD5 sum has changed, delete it. Otherwise the resource is left
        // in the cache and can be reused by the new service worker.
        if (!RESOURCES[key] || RESOURCES[key] != oldManifest[key]) {
          await contentCache.delete(request);
        }
      }
      // Populate the cache with the app shell TEMP files, potentially overwriting
      // cache files preserved above.
      for (var request of await tempCache.keys()) {
        var response = await tempCache.match(request);
        await contentCache.put(request, response);
      }
      await caches.delete(TEMP);
      // Save the manifest to make future upgrades efficient.
      await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
      // Claim client to enable caching on first launch
      self.clients.claim();
      return;
    } catch (err) {
      // On an unhandled exception the state of the cache cannot be guaranteed.
      console.error('Failed to upgrade service worker: ' + err);
      await caches.delete(CACHE_NAME);
      await caches.delete(TEMP);
      await caches.delete(MANIFEST);
    }
  }());
});
// The fetch handler redirects requests for RESOURCE files to the service
// worker cache.
self.addEventListener("fetch", (event) => {
  if (event.request.method !== 'GET') {
    return;
  }
  var origin = self.location.origin;
  var key = event.request.url.substring(origin.length + 1);
  // Redirect URLs to the index.html
  if (key.indexOf('?v=') != -1) {
    key = key.split('?v=')[0];
  }
  if (event.request.url == origin || event.request.url.startsWith(origin + '/#') || key == '') {
    key = '/';
  }
  // If the URL is not the RESOURCE list then return to signal that the
  // browser should take over.
  if (!RESOURCES[key]) {
    return;
  }
  // If the URL is the index.html, perform an online-first request.
  if (key == '/') {
    return onlineFirst(event);
  }
  event.respondWith(caches.open(CACHE_NAME)
    .then((cache) =>  {
      return cache.match(event.request).then((response) => {
        // Either respond with the cached resource, or perform a fetch and
        // lazily populate the cache only if the resource was successfully fetched.
        return response || fetch(event.request).then((response) => {
          if (response && Boolean(response.ok)) {
            cache.put(event.request, response.clone());
          }
          return response;
        });
      })
    })
  );
});
self.addEventListener('message', (event) => {
  // SkipWaiting can be used to immediately activate a waiting service worker.
  // This will also require a page refresh triggered by the main worker.
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
    return;
  }
  if (event.data === 'downloadOffline') {
    downloadOffline();
    return;
  }
});
// Download offline will check the RESOURCES for all files not in the cache
// and populate them.
async function downloadOffline() {
  var resources = [];
  var contentCache = await caches.open(CACHE_NAME);
  var currentContent = {};
  for (var request of await contentCache.keys()) {
    var key = request.url.substring(origin.length + 1);
    if (key == "") {
      key = "/";
    }
    currentContent[key] = true;
  }
  for (var resourceKey of Object.keys(RESOURCES)) {
    if (!currentContent[resourceKey]) {
      resources.push(resourceKey);
    }
  }
  return contentCache.addAll(resources);
}
// Attempt to download the resource online before falling back to
// the offline cache.
function onlineFirst(event) {
  return event.respondWith(
    fetch(event.request).then((response) => {
      return caches.open(CACHE_NAME).then((cache) => {
        cache.put(event.request, response.clone());
        return response;
      });
    }).catch((error) => {
      return caches.open(CACHE_NAME).then((cache) => {
        return cache.match(event.request).then((response) => {
          if (response != null) {
            return response;
          }
          throw error;
        });
      });
    })
  );
}
