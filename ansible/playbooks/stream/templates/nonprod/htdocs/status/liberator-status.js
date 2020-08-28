(function () {

var onSubscriptionStatus = function (subscription, event) { };
var onSubscriptionError = function (subscription, event) { };
	
var streamlink = caplin.streamlink.StreamLinkFactory.create({
	liberator_urls: (window.location.protocol.slice(-2, -1) === "s" ? "rttps" : "rttp") + "://" + window.location.host,
	username: "admin",
	password: "{{ streamStatusPassword }}"
});
document.getElementById("StreamLink-Version").firstChild.nodeValue = streamlink.getVersion();

streamlink.addConnectionListener({
	onConnectionFail: function (reason) {
		document.getElementById("container").className = "disconnected";
		streamlink.connect();
	},
	onConnectionStatusChange: function (event) {
		switch (event.getConnectionState()) {
			case "RECONNECTED":
			case "LOGGEDIN":
				document.getElementById("container").className = "connected";
				break;
	}
	}
});
streamlink.connect();

// gets the node id of the Liberator StreamLink is connected to
var getCurrentNodeId = function (callback) {
	if (getCurrentNodeId.id !== undefined) {
		callback(getCurrentNodeId.id);
		return;		
	}
	var subscription = streamlink.subscribe("/SYSTEM/INFO", {
		onRecordUpdate: function (subscription, event) {
			subscription.unsubscribe();
			getCurrentNodeId.id = event.getFields()["NodeID"];
			callback(getCurrentNodeId.id);
		},
		onSubscriptionStatus: onSubscriptionStatus,
		onSubscriptionError: onSubscriptionError
	});
};

(function () {
	
	var clusteringTables = {};
	
	var subscribeToSessionData = function (subject, nodeId) {
		streamlink.subscribe(subject, {
			onRecordUpdate: function (subscription, event) {
				var fields = event.getFields();
				for (var fieldName in fields) {
					var element = document.getElementById("sljs-" + nodeId + fieldName) || { firstChild : {} };
					element.firstChild.nodeValue = fields[fieldName];
				}
			},
			onSubscriptionStatus: onSubscriptionStatus,
			onSubscriptionError: onSubscriptionError
		});
	};
	
	var createClusteringTable = function (subject, containerId, currentNodeId, nodeId) {
		if (clusteringTables[nodeId]) return;
		
		clusteringTables[nodeId] = document.createElement("div");
		clusteringTables[nodeId].innerHTML =
		'<table class="status-one-third status-table">' +
			'<tbody>' +
				'<tr>' +
					'<th>Liberator </th>' +
					'<td>' + (currentNodeId == nodeId ? nodeId + ' (this server)' : nodeId) + '</td>' +
				'</tr>' +
				'<tr>' +
					'<th>Current Sessions</th>' +
					'<td id="sljs-' + nodeId + 'Sessions">Please Wait...</td>' +
				'</tr>' +
				'<tr>' +
					'<th>Peak Sessions</th>' +
					'<td id="sljs-' + nodeId + 'MaxSessions">Please Wait...</td>' +
				'</tr>' +
				'<tr>' +
					'<th scope="row">Number of Objects</th>' +
					'<td id="sljs-' + nodeId + 'NumObjects">Please Wait...</td>' +
				'</tr>' +
			'</tbody>' +
		'</table>';
		document.getElementById(containerId).appendChild(clusteringTables[nodeId]);
		subscribeToSessionData(subject, nodeId);
	};
		
	// display general status info
	getCurrentNodeId(function (currentNodeId) {
		var subscriptionListener = {
			onRecordUpdate: function (subscription, event) {
				var fields = event.getFields();
				for (var fieldName in fields) {
					var element = document.getElementById("sljs-" + fieldName) || { firstChild : {} };
					var notInGracePeriod = fieldName === "GracePeriodExpireTime" && fields[fieldName] === "-"
					element.firstChild.nodeValue = notInGracePeriod ? "Not in Grace Period" : fields[fieldName];
				}
			},
			onSubscriptionStatus: onSubscriptionStatus,
			onSubscriptionError: function (subscription, event) { alert(event); }
		};
		streamlink.subscribe("/SYSTEM/INFO", subscriptionListener);
		streamlink.subscribe("/SYSTEM/LICENSE", subscriptionListener);
		subscribeToSessionData("/SYSTEM/NODE-" + currentNodeId + "/INFO", "Global");
	});
	
	// display info for all Liberators in cluster
	getCurrentNodeId(function (currentNodeId) {
		streamlink.subscribe("/SYSTEM", {
				onDirectoryUpdate: function (subscription, event) {
					var directoryElements = event.getChangedElements();
					for (var i = 0; i !== directoryElements.length; ++i) {
						var subject = directoryElements[i].getSubject();
						if (subject.match(/^NODE-(\d+)$/) && directoryElements[i].isAdded()) {
							var nodeId = subject.match(/^NODE-(\d+)$/)[1];
							createClusteringTable("/SYSTEM/NODE-" + nodeId + "/INFO", "clustering-status", currentNodeId, nodeId);
						}
					}
				},
				onSubscriptionStatus: onSubscriptionStatus,
				onSubscriptionError: onSubscriptionError
			});
		});
	
})();

// display a warning if licence is expiring
streamlink.subscribe("/SYSTEM/LICENSE", {
		onRecordUpdate: function (subscription, event) {
			var fields = event.getFields();
			var licenceAlert = document.getElementById("licence-alert");
			if (fields["StatusText"] !== undefined) {
				licenceAlert.firstChild.nodeValue = fields["StatusText"];
			}
			switch (fields["StatusValue"])
			{
				case "0":
					licenceAlert.className = "hidden";
					break;
				case "1":
				case "2":
					licenceAlert.className = "alert alert-warning";
					break;
				case "3":
					licenceAlert.className = "alert alert-error";
					break;
			}
		},
		onSubscriptionStatus: onSubscriptionStatus,
		onSubscriptionError: onSubscriptionError
		
	});

(function () {

	var recordSubscriptionListener = {
		onRecordUpdate: function (subscription, event) {
			var subject = event.getSubject();		
			var fields = event.getFields();
			for (var fieldName in fields) {
				var element = document.getElementById("sljs-" + subject + "/" + fieldName) || { firstChild : {} };
				if (fieldName === "ServiceState" || fieldName === "SourceStatus") {
					switch (fields[fieldName]) {
						case "UP":
						case "OK":
							element.innerHTML = '<div class="status-up">UP<span></span></div>';
							break;
						case "DOWN":
							element.innerHTML = '<div class="status-down">DOWN<span></span></div>';
							break;
						case "LIMITED":
							element.innerHTML = '<div class="status-limited">LIMITED<span></span></div>';
							break;
						default:
							element.innerHTML = '...';
							element.firstChild.nodeValue = fields[fieldName];
							break;
					}
				} else if (fieldName === "StatusValue") {
					var statusElement = document.getElementById("sljs-" + subject + "/StatusText") || { firstChild : {} };
					var statusText = statusElement.firstChild.nodeValue || statusElement.firstChild.firstChild.nodeValue;
					switch (fields[fieldName]) {
						case "0":
							statusElement.innerHTML = '<div class="status-up">' + statusText + '<span></span></div>';
							break;
						case "1":
						case "2":
							statusElement.innerHTML = '<div class="status-limited"' + statusText + '<span></span></div>';
							break;
						case "3":
							statusElement.innerHTML = '<div class="status-down">' + statusText + '<span></span></div>';
							break;
					}
				} else if (fieldName === "StatusText") {
					var statusTextElement = element.firstChild.firstChild || element.firstChild;
					statusTextElement.nodeValue = fields[fieldName];
				} else {
					element.firstChild.nodeValue = fields[fieldName];
				}
			}
		},
		onSubscriptionStatus: onSubscriptionStatus,
		onSubscriptionError: onSubscriptionError
	};
	
	var tables = {};
	var createTwoColumnTableTable = function (subject, id, fields, labels) {
		if (tables[subject]) return;
		
		var getTwoColumnTableString = function (subject, fields, labels) {
			var result = [];
			result.push('<table class="status-one-third status-table">');
			result.push('<tbody>');
			for (var i = 0; i !== labels.length; ++i) {
				result.push('<tr>');
				result.push('<th>' + labels[i] + '</th>');
				result.push(fields[i] === null 
						? '<td>(All)</td>' 
						: '<td id="sljs-' + subject + '/' + fields[i] + '">Please Wait...</td>');
				result.push('</tr>');
			}
			result.push('</tbody>');
			result.push('</table>');
			return result.join('');
		};
		tables[subject] = document.createElement("div");
		tables[subject].innerHTML = getTwoColumnTableString(subject, fields, labels);
		document.getElementById(id).appendChild(tables[subject]);
		streamlink.subscribe(subject, recordSubscriptionListener);
	};
	
	var createSubscriptionListener = function (id, fields, labels) {
		return {
			onDirectoryUpdate: function (subscription, event) {
				var directoryElements = event.getChangedElements();
				var directorySubject = event.getSubject();
				for (var i = 0; i !== directoryElements.length; ++i) {
					if (directoryElements[i].isAdded()) {
						var subject = directorySubject + "/" + directoryElements[i].getSubject();
						if (!subject.match(/^\/SYSTEM\/NODE-\d+\/INFO$/) 
									&& !subject.match(/^\/SYSTEM\/NODE-\d+\/SERVICE$/)) {
							createTwoColumnTableTable(subject, id, fields, labels);
						}
					}
				}
			},
			onSubscriptionStatus: onSubscriptionStatus,
			onSubscriptionError: onSubscriptionError
		};
	};
	
	// display info on licensing
	createTwoColumnTableTable(
			"/SYSTEM/LICENSING/UNIQUE_USERS",
			"licensing-status",
			[null, "MaxUniqueUsers", "UniqueUsers", "RejectedUniqueUsers", "StatusText"],
			["Name", "Max Logins", "Cumulative Logins", "Failed Logins Count", "Status"]
		);
	streamlink.subscribe("/SYSTEM/LICENSING/APPLICATION", createSubscriptionListener(
			"licensing-status",
			["ApplicationName", "LicencedSessionLimit", "TotalSessions", "FailedSessions", "StatusText"],
			["Name", "Max Logins", "Cumulative Logins", "Failed Logins Count", "Status"]
		));
	streamlink.subscribe("/SYSTEM/LICENSING/TRADINGGROUP", createSubscriptionListener(
			"licensing-status",
			["TradingGroupName", "LicencedUsageLimit", "Usage", "FailedUsage", "StatusText"],
			["Name", "Max Users", "Cumulative Users", "Rejected Users", "Status"]
		));

	// display info on DataSources
	getCurrentNodeId(function (currentNodeId) {
			streamlink.subscribe("/SYSTEM/NODE-" + currentNodeId + "/SERVICE", createSubscriptionListener(
					"dataservice-status",
					["ServiceName", "ServiceState", "ServiceDateTime"], 
					["Name", "Status", "Last Change"]
				));
			streamlink.subscribe("/SYSTEM/NODE-" + currentNodeId, createSubscriptionListener(
					"datasources-status",
					["SourceID", "SourceName", "SourceStatus", "SourceDateTime", "SourceAddr", "SourceLabel"], 
					["ID", "Name", "Status", "Last Change", "Address", "Label"]
				));
		});

})();

})();
