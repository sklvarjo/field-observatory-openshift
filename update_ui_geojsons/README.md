

### Secret TOKEN for cloning the private repo

This is gitignored and given to the builder as a secret so it is not included in the final image. 

Get the correct token from any user with rights to read the repository. 
The token is classic. 
In Github go to users settings->developer options -> personal access tokens -> Tokens (classic)
Create a new classic token with full rights to repos.

Copy paste the token into file secret_token.txt (same folder as this README.md) or
 
    echo "ghp_XXXXXXXXXXXXXXXXXXXX" > secret_token.txt

### Building the container

    export DOCKER_BUILDKIT=1;docker build --secret id=git_token,src=secret_token.txt -f update_ui_geojsons.Dockerfile -t update_ui_geojsons .

### Running the container locally

    docker run --rm -u $(id -u):$(id -g) -v $(pwd)/testdata:/data update_ui_geojsons

/app/fieldobs_utils/fieldobs_utils
