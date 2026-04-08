import logging
import os
import sys
import traceback
from contextlib import asynccontextmanager
from typing import Dict

from fastapi import FastAPI

from .backends.backend import InstanceExists
from .types import CreateInstanceRequest
from .utils import load_backend, load_database

MAX_INSTANCES_PER_TEAM = int(os.environ.get("MAX_INSTANCES_PER_TEAM", "10"))


@asynccontextmanager
async def lifespan(app: FastAPI):
    global database, backend
    database = load_database()
    backend = load_backend(database)

    logging.root.setLevel(logging.INFO)

    yield


app = FastAPI(lifespan=lifespan)


@app.post("/instances")
def create_instance(args: CreateInstanceRequest):
    logging.info("launching new instance: %s", args["instance_id"])

    # Enforce max instances per team
    instance_id = args["instance_id"]
    if not instance_id.startswith("chal-"):
        return {
            "ok": False,
            "message": "invalid instance_id format",
        }

    # Extract team_id: everything after the last hyphen following "chal-{challenge}-"
    parts = instance_id.split("-", 2)
    team_id = parts[2] if len(parts) > 2 else instance_id
    count = database.count_team_instances(team_id)
    if count >= MAX_INSTANCES_PER_TEAM:
        active = database.get_team_instance_names(team_id)
        logging.warning("team %s has reached max instances (%d/%d): %s", team_id, count, MAX_INSTANCES_PER_TEAM, active)
        return {
            "ok": False,
            "message": f"max instances per team reached ({count}/{MAX_INSTANCES_PER_TEAM}). Kill an instance first. Active: {', '.join(active)}",
        }

    try:
        user_data = backend.launch_instance(args)
    except InstanceExists:
        logging.warning("instance already exists: %s", args["instance_id"])

        return {
            "ok": False,
            "message": "instance already exists",
        }
    except Exception as e:
        logging.error(
            "failed to launch instance: %s", args["instance_id"], exc_info=e
        )
        return {
            'ok': False,
            'message': 'an internal error occurred',
        }

    logging.info("launched new instance: %s", args["instance_id"])
    return {
        "ok": True,
        "message": "instance launched",
        "data": user_data,
    }

@app.get("/instances/{instance_id}")
def get_instance(instance_id: str):
    user_data = database.get_instance(instance_id)
    if user_data is None:
        return {
            'ok': False,
            'message': 'instance does not exist',
        }
    
    return {
        'ok': True,
        'message': 'fetched metadata',
        'data': user_data
    }

@app.post("/instances/{instance_id}/metadata")
def update_metadata(instance_id: str, metadata: Dict[str, str]):
    try:
        database.update_metadata(instance_id, metadata)
    except:
        return {
            'ok': False,
            'message': 'instance does not exist'
        }
    
    return {
        'ok': True,
        'message': 'metadata updated',
    }
        

@app.delete("/instances/{instance_id}")
def delete_instance(instance_id: str):
    logging.info("killing instance: %s", instance_id)

    instance = backend.kill_instance(instance_id)
    if instance is None:
        return {
            "ok": False,
            "message": "no instance found",
        }

    return {
        "ok": True,
        "message": "instance deleted",
    }
