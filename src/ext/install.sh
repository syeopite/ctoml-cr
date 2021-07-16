git clone --depth 1 "https://github.com/cktan/tomlc99"
cd tomlc99
make
mv libtoml.a ../

# Cleanup 
cd ../
rm -rf tomlc99 