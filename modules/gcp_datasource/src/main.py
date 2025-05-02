import re
import functions_framework
from flask import Request, jsonify
from google.cloud import compute_v1
import google.cloud.logging
import logging

client = google.cloud.logging.Client()
client.setup_logging(log_level=logging.INFO)
images_client = compute_v1.ImagesClient()


def extract_image_version(versioned_image_name: str, image_name: str):
    gcp_image_version = versioned_image_name.removeprefix(f"{image_name}---")

    match gcp_image_version:
        case _ if re.match(r"^\d{10,}$", gcp_image_version):
            # If there are 10 or more digits,
            # the image is most likely versioned with an unix timestamp.
            # For example, image-name---1744888624
            return gcp_image_version
        case _:
            # Otherwise we assume, for example,
            # image-name---1-2-3 or image-name---1-5, etc.
            # 1-2-3 becomes `1.2.3`, and 1-5 becomes `1.5`.
            return gcp_image_version.replace("-", ".", 3)


def images_to_renovate_response(images, project: str, name: str):
    data = {"releases": []}

    try:
        for image in images:
            data["releases"].append(
                {
                    "version": extract_image_version(image.name, name),
                    "releaseTimestamp": image.creation_timestamp,
                    "sourceUrl": f"https://console.cloud.google.com/compute/imagesDetail/projects/{project}/global/images/{image.name}"
                }
            )
            logging.debug(f"added to renovate release response for {project}/{name}: {data['releases'][-1]}")
    except Exception as err:
        raise Exception(f"error creating releases response: {err}")

    return data


def fetch_image_releases(project: str, name: str) -> dict:
    # all versioned images names are of the format:
    # <name>---<version>
    regex = re.compile(f"{name}---.*")

    request = compute_v1.ListImagesRequest(project=project)
    images = images_client.list(request=request)

    matching_images = [
        image for image in images \
        if regex.match(image.name) and image.status == "READY"
    ]

    logging.info(f"found {len(matching_images)} images for {project}/{name}")

    return images_to_renovate_response(matching_images, project, name)


@functions_framework.http
def main(request: Request):
    method = request.method
    path = request.path

    if method == "GET" and path.startswith("/v1/releases/images/"):
        path = path.replace("/v1/releases/images/", "")
        path = path.strip("/")
        path = path.split("/")

        try:
            image_project = path[0]
        except:
            logging.error(f"error extracting image project from path: {path}")
            return jsonify({"error": f"error extracting image project from path"}), 400

        try:
            image_name = path[1]
        except:
            logging.error(f"error extracting image name from path: {path}")
            return jsonify({"error": f"error extracting image name from path"}), 400

        try:
            return jsonify(fetch_image_releases(image_project, image_name)), 200
        except Exception as err:
            logging.error(f"error fetching image releases: {err}")
            return jsonify({"error": f"error fetching image releases"}), 400

    return jsonify({"error": f"{method} {path} not found"}), 404
