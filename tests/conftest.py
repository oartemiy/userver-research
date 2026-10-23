import handlers.hello_pb2_grpc as hello_services 
import pytest
import pytest_userver.config

from testsuite.databases.pgsql import discover 

pytest_plugins = [
    'pytest_userver.plugins.core',
    'pytest_userver.plugins.postgresql', 
    'pytest_userver.plugins.mongo', 
    'pytest_userver.plugins.grpc', 
]


MONGO_COLLECTIONS = {
    'hello_users': {
        'settings': {
            'collection': 'hello_users',
            'connection': 'admin',
            'database': 'admin',
        },
        'indexes': [],
    },
}


@pytest.fixture(scope='session')
def mongodb_settings():
    return MONGO_COLLECTIONS




@pytest.fixture
def grpc_service(grpc_channel, service_client):
    return hello_services.HelloServiceStub(grpc_channel)




@pytest.fixture(scope='session')
def initial_data_path(service_source_dir):
    """Path for find files with data"""
    return [
        service_source_dir / 'postgresql/data',
    ]


@pytest.fixture(scope='session')
def pgsql_local(service_source_dir, pgsql_local_create):
    """Create schemas databases for tests"""
    databases = discover.find_schemas(
        'research',
        [service_source_dir.joinpath('postgresql/schemas')],
    )
    return pgsql_local_create(list(databases.values()))



@pytest.fixture(scope='session')
@pytest_userver.config.patch
def userver_pg_config(pgsql_local):
    """Patch only the PostgreSQL component.

    The service has both PostgreSQL and MongoDB components, and both use a
    ``dbconnection`` key. The stock fixture rejects more than one such
    component, so patch the PostgreSQL component explicitly by name.
    """
    if not pgsql_local:
        raise ValueError('Override pgsql_local so testsuite can start PostgreSQL')
    if len(pgsql_local) > 1:
        raise ValueError(f'Expected one PostgreSQL database, got {list(pgsql_local)}')

    uri = list(pgsql_local.values())[0].get_uri()

    def _patch_config(config_yaml, config_vars):
        components = config_yaml['components_manager']['components']
        component = components.get('postgres-db-1')
        if component is None:
            raise ValueError('postgres-db-1 component is missing in static config')
        component['dbconnection'] = uri
        component.pop('dbalias', None)

    return _patch_config
