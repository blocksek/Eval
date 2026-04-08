import json
import sqlite3
from typing import List, Optional
from ctf_server.databases import Database
from ctf_server.types import InstanceInfo
from threading import Lock


class SQLiteDatabase(Database):
    def __init__(self, db_path: str):
        super().__init__()

        self.__conn_lock = Lock()
        self.__conn = sqlite3.connect(database=db_path, check_same_thread=False)
        self.__conn.execute(
            """
CREATE TABLE IF NOT EXISTS anvil_instances
(
    instance_id VARCHAR PRIMARY KEY,
    rpc_id VARCHAR,
    instance_data JSON
);"""
        )

    def register_instance(self, instance_id: str, instance: InstanceInfo):
        self.__conn_lock.acquire()
        try:
            cursor = self.__conn.execute(
                """INSERT INTO anvil_instances(instance_id, instance_data) VALUES (?, ?)""",
                (instance_id, json.dumps(instance)),
            )
        finally:
            cursor.close()
            self.__conn_lock.release()

    def update_instance(self, instance_id: str, instance: InstanceInfo):
        self.__conn_lock.acquire()
        try:
            cursor = self.__conn.execute(
                """UPDATE anvil_instances SET instance_data = ? WHERE instance_id = ?""",
                (json.dumps(instance), instance_id),
            )
        finally:
            cursor.close()
            self.__conn_lock.release()

    def unregister_instance(self, instance_id: str) -> InstanceInfo:
        self.__conn_lock.acquire()
        try:
            cursor = self.__conn.execute(
                """DELETE FROM anvil_instances WHERE instance_id = ? RETURNING instance_data""", (instance_id,)
            )
            row = cursor.fetchone()
            if row is None:
                return None
            
            return json.loads(row[0])
        finally:
            cursor.close()
            self.__conn_lock.release()

    def get_all_instances(self) -> List[InstanceInfo]:
        self.__conn_lock.acquire()
        try:
            cursor = self.__conn.execute(
                """SELECT instance_data FROM anvil_instances"""
            )
            result = []
            while True:
                row = cursor.fetchone()
                if row is None:
                    break

                result.append(json.loads(row[0]))
            return result
        finally:
            cursor.close()
            self.__conn_lock.release()
    
    def get_instance_by_external_id(self, rpc_id: str) -> InstanceInfo | None:
        self.__conn_lock.acquire()
        try:
            cursor = self.__conn.execute(
                """SELECT instance_data FROM anvil_instances WHERE rpc_id = ?""", (rpc_id,)
            )
            row = cursor.fetchone()
            if row is None:
                return None
            
            return json.loads(row[0])
        finally:
            cursor.close()
            self.__conn_lock.release()

    def get_instance(self, instance_id: str) -> InstanceInfo | None:
        self.__conn_lock.acquire()
        try:
            cursor = self.__conn.execute(
                """SELECT instance_data FROM anvil_instances WHERE instance_id = ?""", (instance_id,)
            )
            row = cursor.fetchone()
            if row is None:
                return None
            
            return json.loads(row[0])
        finally:
            cursor.close()
            self.__conn_lock.release()

    def count_team_instances(self, team_id: str) -> int:
        self.__conn_lock.acquire()
        try:
            cursor = self.__conn.execute(
                """SELECT COUNT(*) FROM anvil_instances WHERE instance_id LIKE ?""",
                (f"chal-%-{team_id}",),
            )
            row = cursor.fetchone()
            return row[0] if row else 0
        finally:
            cursor.close()
            self.__conn_lock.release()

    def get_team_instance_names(self, team_id: str) -> list:
        self.__conn_lock.acquire()
        try:
            cursor = self.__conn.execute(
                """SELECT instance_id FROM anvil_instances WHERE instance_id LIKE ?""",
                (f"chal-%-{team_id}",),
            )
            names = []
            for row in cursor.fetchall():
                name = row[0][len("chal-"):-len(f"-{team_id}")]
                names.append(name)
            return sorted(names)
        finally:
            cursor.close()
            self.__conn_lock.release()
