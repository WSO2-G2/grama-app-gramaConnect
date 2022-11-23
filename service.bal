import ballerinax/twilio;
import ballerinax/mysql.driver as _;
import ballerina/sql;
import ballerinax/mysql;
import ballerinax/mysql.driver as _;
import ballerina/http;

configurable int PORT = ?;
configurable string DB = ?;
configurable string DB1 = ?;
configurable string PASSWORD = ?;
configurable string USER = ?;
configurable string HOST = ?;
configurable string SID = ?;
configurable string AUTHTOKEN = ?;
configurable string FROMPHONE = ?;

type request record {
    string nic;
    string address;
    string image;
    string status;
    string phone;
    string email;
};

type person record {
    int userId;
    string nic;
    string name;
};

type status record {
    string status;
};

twilio:Client twilioEp = check new (twilioConfig = {
    auth: {
        accountSId: SID,
        authToken: AUTHTOKEN
    }
});

# A service representing a network-accessible API
# bound to port `9090`.
# + fromPhone - The twilio phone number which the sms will originate from. 
# + msg - Message body of the sms. 
# + toPhone - The phone number which the sms will be sent to.
# + return - sendSMS function returns the sms response or an error.

public function sendSMS(string fromPhone, string msg, string toPhone) returns twilio:SmsResponse|error? {
    twilio:SmsResponse|error response = twilioEp->sendSms(fromPhone, toPhone, msg);
    return response;
}

service / on new http:Listener(9090) {

    resource function get getdetails(string nic) returns person|error? {
        mysql:Client mysqlEp = check new (host = HOST, user = USER, password = PASSWORD, database = DB1, port = PORT);

        person|error queryRowResponse = mysqlEp->queryRow(sqlQuery = `SELECT * FROM person WHERE nic = ${nic}`);
        error? e = mysqlEp.close();
        if (e is error) {
            return e;
        }
        return queryRowResponse;

    }

    resource function get requestdetails(string nic) returns request|error? {
        mysql:Client mysqlEp2 = check new (host = HOST, user = USER, password = PASSWORD, database = DB, port = PORT);

        request|error queryRowResponse = mysqlEp2->queryRow(sqlQuery = `SELECT * FROM request WHERE nic = ${nic}`);
        error? e = mysqlEp2.close();
        if (e is error) {
            return e;
        }
        return queryRowResponse;

    }

    resource function patch updateStatus(@http:Payload status payload, string nic, string phone) returns sql:ExecutionResult|error {
        mysql:Client mysqlEp1 = check new (host = HOST, user = USER, password = PASSWORD, database = DB, port = PORT);

        sql:ExecutionResult executeResponse = check mysqlEp1->execute(sqlQuery = `UPDATE request SET  status = ${payload.status} WHERE nic = ${nic}`);
        error? e = mysqlEp1.close();
        if (e is error) {
            return e;
        }
        if (payload.status == "Accepted") {
            twilio:SmsResponse|error? response = sendSMS(FROMPHONE, "Your grama certificate for the NIC " + nic + " is ready. Please visit the website for more details.", phone);
        } else {
            twilio:SmsResponse|error? response = sendSMS(FROMPHONE, "Your grama certificate for the NIC " + nic + " has been rejected. Please visit the website for more details.", phone);
        }

        return executeResponse;

    }

    resource function get getrequests(string gnd) returns request[]|error? {
        mysql:Client mysqlEp5 = check new (host = HOST, user = USER, password = PASSWORD, database = DB, port = PORT);
        request[] requests = [];

        stream<request, error?> queryResponse = mysqlEp5->query(sqlQuery = `SELECT * FROM request WHERE status = "Pending"`);
        error? e = mysqlEp5.close();
        if (e is error) {
            return e;
        }
        check from request request in queryResponse
            do {
                requests.push(request);
            };
        check queryResponse.close();

        return requests;

    }

}
