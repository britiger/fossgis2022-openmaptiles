# FOSSGIS 2022 - Demosession OpenMapTiles

## Übersicht der Schritte
- Klonen der Repos
- Datenbeschaffung - Beispiel Brandenburg/Teltow-Fläming
- Generierung .mbtiles-Datei
- Anpassung der Definition
- Generierung .mbtiles-Datei
- Sytling mit Maputnik
- Darstellung auf der Karte
  - als Offline-Karte

## Benötigte repos Klonen
```bash
git clone https://github.com/openmaptiles/openmaptiles
git clone https://github.com/openmaptiles/fonts
git clone https://github.com/openmaptiles/positron-gl-style
git clone https://github.com/maplibre/maplibre-gl-js
```

## OpenMapTiles
- `cd openmaptiles` 
- Basiert auf Docker

### Download eines Extrakts
- kann über OpenMapTiles passieren (geofabrik oder bbike)
- Alterntiv Extrakt-Service (kleine Dateien zur Entwicklung) - https://extract.bbbike.org/
- Hier Teltow-Fläming Nord (BBOX: `12.964,52.129,13.712,52.417`)

### Konfiguration
- `.env` für OpenMapTiles
  - BBOX-Variable aus `data/*.bbox` nach quickstart.
  - Zoom-Level MIN/MAX 0-14

### Erste Standard-Karte generieren
- Karte generieren `./quickstart.sh brandenburg`
  - Alternativ ein Extakt (Ablage in `data`-Ordner, anbage oder suffix `.osm.pbf`)
- Ergebnis: `data/tiles.mbtiles`

### Prüfe die Karte
- OpenMapTiles bietet viele Tools u.a. Tileserver
  - `make start-tileserver`
  - Nutzt derzeit Mapbox-Karte
- Kann auch mit `qgis` geprüft werden
  - `qgis data/tiles.mbtiles`

### Was brauche ich jetzt?
- Tagging der OpenStreetMap Objekte ermitteln
- Beispiel: Marker für Gas-Leitungen
- Seite für marker:
    - https://wiki.openstreetmap.org/wiki/Key:marker
        - `marker=*`
        - `utility=gas`
        - `ref=*`
        - `operator=*`
- Variante "Altbestand"
    - https://wiki.openstreetmap.org/wiki/Tag:pipeline%3Dmarker
        - `substance=gas`
        - `pipeline=marker`
        - `pipeline:ref=*`
        - `ref=*`

### Layer hinzufügen
- Mögliche Varianten:
  1. Neuen Layer zu vorhandenen hinzufügen (Gesamtdatei mit allen Layern)
  2. Vector-Datei nur mit spezifischer Information + Standard-Vector-Datei

- Neuen Ordner in `layer/` erstellen
  - `yaml`-Datei für imposm3 erstellen (mapping.yaml)
  - `sql`-Datei(n) zum Zusammenstellen der Abfrage ggf. weiter Dateien
  - `yaml`-Datei für Konfiguration Layer erstellen
- Neuen Layer in `openmaptiles.yaml` ergänzen

### Karte neu generien
- Nutzung Quickstart, auch einzelne Schritte möglich
  - Quickstart ist nur zusammenstellung der `make`-Befehle
  - ggf. eigene Zwischenschritte notwendig

## Style konfigurieren mit Maputnik
- `make start-maputnik`
- http://localhost:8088 
- Style auswählen: [Positron](https://github.com/openmaptiles/positron-gl-style)
- "Set data source" / "TileJSON URL" http://localhost:8090
- Nutzung von 'Inspect'-Ansicht zur Anzeige der vorhandene Layerdaten
- Styling anpassen
  - Add Layer
    - `gas_dot` (circle)
    - `gas_ref` (symbol) - Text: `{ref}` - einen Font angeben
    - `gas_pipeline` (symbol) - Text: `{pipeline_ref}`
- Export des Styles als `json`-Datei
- Vorbereitung für Offline-Server
  - Setzen der zukünftigen URLs für eigenen Server
```
...
  "sources": {
    "openmaptiles": {"type": "vector", "url": "http://localhost:3000/services/tiles"}
  },
  "sprite": "http://localhost:3000/sprite",
  "glyphs": "http://localhost:3000/fonts/{fontstack}/{range}.pbf",
...
```
  - Möglichen `fontstack` auf einen Font reduzieren: `, "Noto Sans Italic"` `, "Noto Sans Regular"` löschen

## Offline-Vector-Server

### Maplibre-GL-js generieren
- `cd ../maplibre-gl-js`
- Generierung starten:
```bash
npm install
npm run build-prod-min
npm run build-css
```
- Alternativ Download der fertigen Dateien: https://github.com/maplibre/maplibre-gl-js

### Fonts generieren
- Fonts müssen im `pbf`-Format vorliegen
- Hiermit kein "fontstack" möglich, wenn einfacher http-Server
  - Beim Styling darauf achten, immer einen Font anzugeben (Default 2 Fonts auf 1 reduzieren)
  - Alterntive ermöglich mehere Fonts je Layer: https://github.com/furkot/map-glyph-server
- In den Verzeichnissen können eigene Fonts ergänzt werden
- `cd ../fonts`
- Generierung starten: 
```bash
npm install
node generate.js
```

### Sprites generieren
- Im Style benötigte Icons müssen generiert werden
- Generierung von Icon-Dateien zum Style
- `cd ../positron-gl-style`
- Benötigte Node-Packages einrichten:
```bash
export PATH=`pwd`/node_modules/.bin/:$PATH
npm install @beyondtracks/spritezero-cli
```
- Generierung starten:
```bash
spritezero sprite ./icons
spritezero --retina sprite@2x ./icons
```

### Alle benötigte Dateien zusammenkopieren
- Webverzeichnis `webdir`
- `cd ..`
- Dateien kopieren
```bash
# Fonts kopieren
cp -r fonts/_output webdir/fonts
# Sprites kopieren
cp positron-gl-style/sprite* webdir/
# Maplibre kopieren
cp maplibre-gl-js/dist/maplibre-gl.* webdir/
```

### HTML-Seite erstellen
- Anpassung aus Maplibe-Beispielen: https://maplibre.org/maplibre-gl-js-docs/example/simple-map/
- Siehe `final_files/index.html`

### lightttpd konfig
- Siehe `final_files/lighttps.conf`
- Webserver auf Port 3000
- Stellt auch Proxy für mbtiles-Server

### mbtileserver starten
- Einfacher in go geschriebener Tiles-Server
- Kann mehere mbtiles-Zur Verfügung stellen
- im Verzeichnis `openmaptiles/data`
- `docker run --rm -it -p 8089:8000 -v $(pwd):/tilesets  consbio/mbtileserver`
- Verfügbare Tiles prüfen: http://localhost:8089/services
- Alternative: Auspacken der einzelnen Tiles ins `webdir`
  - Tool: [mbutil]{https://github.com/anilkunchalaece/mbutil}
  - `mb-util --image_format=pbf openmaptiles/data/tiles.mbtiles webdir/tiles/`
