import ballerinax/mysql.driver as _;
import ballerina/sql;
import ballerinax/mysql;
import ballerinax/mysql.driver as _;
import ballerina/http;

type request record {
    string nic;
    string address;
    string image;
    string status;
    string gnd;
};

type person record {
    int userId;
    string nic;
    string name;
};

type status record {
    string status;
};

# A service representing a network-accessible API
# bound to port `9090`.
service / on new http:Listener(9090) {

    resource function get getdetails(string nic) returns person|error? {
        mysql:Client mysqlEp = check new (host = "workzone.c6yaihe9lzwl.us-west-2.rds.amazonaws.com", user = "admin", password = "Malithi1234", database = "gramaIdentityCheck", port = 3306);

        person|error queryRowResponse = mysqlEp->queryRow(sqlQuery = `SELECT * FROM person WHERE nic = ${nic}`);
        error? e = mysqlEp.close();
        if (e is error) {
            return e;
        }
        return queryRowResponse;

    }

    resource function get requestdetails(string nic) returns request|error? {
        mysql:Client mysqlEp2 = check new (host = "workzone.c6yaihe9lzwl.us-west-2.rds.amazonaws.com", user = "admin", password = "Malithi1234", database = "gramaAddressCheck", port = 3306);

        request|error queryRowResponse = mysqlEp2->queryRow(sqlQuery = `SELECT * FROM request WHERE nic = ${nic}`);
        error? e = mysqlEp2.close();
        if (e is error) {
            return e;
        }
        return queryRowResponse;

    }

    resource function patch updateStatus(@http:Payload status payload, string nic) returns sql:ExecutionResult|error {
        mysql:Client mysqlEp1 = check new (host = "workzone.c6yaihe9lzwl.us-west-2.rds.amazonaws.com", user = "admin", password = "Malithi1234", database = "gramaAddressCheck", port = 3306);

        sql:ExecutionResult executeResponse = check mysqlEp1->execute(sqlQuery = `UPDATE request SET  status = ${payload.status} WHERE nic = ${nic}`);
        error? e = mysqlEp1.close();
        if (e is error) {
            return e;
        }
        return executeResponse;

    }

    resource function get getrequests(string gnd) returns request[]|error? {
        mysql:Client mysqlEp5 = check new (host = "workzone.c6yaihe9lzwl.us-west-2.rds.amazonaws.com", user = "admin", password = "Malithi1234", database = "gramaAddressCheck", port = 3306);
        request[] requests = [];

        stream<request, error?> queryResponse = mysqlEp5->query(sqlQuery = `SELECT * FROM request WHERE gnd = ${gnd} AND status = "Pending"`);
        check from request request in queryResponse
            do {
                requests.push(request);
            };
        check queryResponse.close();

        return requests;

    }

}
