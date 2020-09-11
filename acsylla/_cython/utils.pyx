def uuid_max_from_timestamp(int timestamp):
    cdef CassUuid uuid
    cdef char output[CASS_UUID_STRING_LENGTH]

    cass_uuid_min_from_time(timestamp, &uuid)
    cass_uuid_string(uuid, output)
    return output.decode()


def uuid_min_from_timestamp(int timestamp):
    cdef CassUuid uuid
    cdef char output[CASS_UUID_STRING_LENGTH]

    cass_uuid_max_from_time(timestamp, &uuid)
    cass_uuid_string(uuid, output)
    return output.decode()
