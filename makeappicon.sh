IN=./AppIcon.psd
DIR=./Neocom/Neocom/Assets.xcassets/AppIcon.appiconset
rm -rf $DIR
mkdir $DIR

sips $IN -s format png -s dpiHeight 72 -s dpiWidth 72 -Z 20 --out $DIR/Icon-20@1x.png
sips $IN -s format png -s dpiHeight 72 -s dpiWidth 72 -Z 40 --out $DIR/Icon-20@2x.png
sips $IN -s format png -s dpiHeight 72 -s dpiWidth 72 -Z 60 --out $DIR/Icon-20@3x.png
sips $IN -s format png -s dpiHeight 72 -s dpiWidth 72 -Z 29 --out $DIR/Icon-29@1x.png
sips $IN -s format png -s dpiHeight 72 -s dpiWidth 72 -Z 58 --out $DIR/Icon-29@2x.png
sips $IN -s format png -s dpiHeight 72 -s dpiWidth 72 -Z 87 --out $DIR/Icon-29@3x.png
sips $IN -s format png -s dpiHeight 72 -s dpiWidth 72 -Z 40 --out $DIR/Icon-40@1x.png
sips $IN -s format png -s dpiHeight 72 -s dpiWidth 72 -Z 80 --out $DIR/Icon-40@2x.png
sips $IN -s format png -s dpiHeight 72 -s dpiWidth 72 -Z 120 --out $DIR/Icon-40@3x.png
sips $IN -s format png -s dpiHeight 72 -s dpiWidth 72 -Z 120 --out $DIR/Icon-60@2x.png
sips $IN -s format png -s dpiHeight 72 -s dpiWidth 72 -Z 180 --out $DIR/Icon-60@3x.png
#sips $IN -s format png -s dpiHeight 72 -s dpiWidth 72 -Z 72 --out $DIR/Icon-72@1x.png
#sips $IN -s format png -s dpiHeight 72 -s dpiWidth 72 -Z 144 --out $DIR/Icon-72@2x.png
sips $IN -s format png -s dpiHeight 72 -s dpiWidth 72 -Z 76 --out $DIR/Icon-76@1x.png
sips $IN -s format png -s dpiHeight 72 -s dpiWidth 72 -Z 152 --out $DIR/Icon-76@2x.png
sips $IN -s format png -s dpiHeight 72 -s dpiWidth 72 -Z 167 --out $DIR/Icon-83.5@2x.png
#sips $IN -s format png -s dpiHeight 72 -s dpiWidth 72 -Z 50 --out $DIR/Icon-Small-50@1x.png
#sips $IN -s format png -s dpiHeight 72 -s dpiWidth 72 -Z 100 --out $DIR/Icon-Small-50@2x.png
sips $IN -s format png -s dpiHeight 72 -s dpiWidth 72 -Z 1024 --out $DIR/iTunesArtwork@2x.png

echo '
{
"images" : [
{
"size" : "20x20",
"idiom" : "iphone",
"filename" : "Icon-20@2x.png",
"scale" : "2x"
},
{
"size" : "20x20",
"idiom" : "iphone",
"filename" : "Icon-20@3x.png",
"scale" : "3x"
},
{
"size" : "29x29",
"idiom" : "iphone",
"filename" : "Icon-29@2x.png",
"scale" : "2x"
},
{
"size" : "29x29",
"idiom" : "iphone",
"filename" : "Icon-29@3x.png",
"scale" : "3x"
},
{
"size" : "40x40",
"idiom" : "iphone",
"filename" : "Icon-40@2x.png",
"scale" : "2x"
},
{
"size" : "40x40",
"idiom" : "iphone",
"filename" : "Icon-40@3x.png",
"scale" : "3x"
},
{
"size" : "60x60",
"idiom" : "iphone",
"filename" : "Icon-60@2x.png",
"scale" : "2x"
},
{
"size" : "60x60",
"idiom" : "iphone",
"filename" : "Icon-60@3x.png",
"scale" : "3x"
},
{
"size" : "20x20",
"idiom" : "ipad",
"filename" : "Icon-20@1x.png",
"scale" : "1x"
},
{
"size" : "20x20",
"idiom" : "ipad",
"filename" : "Icon-20@2x.png",
"scale" : "2x"
},
{
"size" : "29x29",
"idiom" : "ipad",
"filename" : "Icon-29@1x.png",
"scale" : "1x"
},
{
"size" : "29x29",
"idiom" : "ipad",
"filename" : "Icon-29@2x.png",
"scale" : "2x"
},
{
"size" : "40x40",
"idiom" : "ipad",
"filename" : "Icon-40@1x.png",
"scale" : "1x"
},
{
"size" : "40x40",
"idiom" : "ipad",
"filename" : "Icon-40@2x.png",
"scale" : "2x"
},
{
"size" : "76x76",
"idiom" : "ipad",
"filename" : "Icon-76@1x.png",
"scale" : "1x"
},
{
"size" : "76x76",
"idiom" : "ipad",
"filename" : "Icon-76@2x.png",
"scale" : "2x"
},
{
"size" : "83.5x83.5",
"idiom" : "ipad",
"filename" : "Icon-83.5@2x.png",
"scale" : "2x"
},
{
"size" : "1024x1024",
"idiom" : "ios-marketing",
"filename" : "iTunesArtwork@2x.png",
"scale" : "1x"
}
],
"info" : {
"version" : 1,
"author" : "xcode"
}
}
' >> $DIR/Contents.json
