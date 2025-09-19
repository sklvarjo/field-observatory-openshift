# local test build
docker build -t icos-downloader -f icos-downloader.Dockerfile .
# local test run
docker run --rm -u $(id -u):$(id -g) -v $(pwd)/testdata:/data icos-downloader
