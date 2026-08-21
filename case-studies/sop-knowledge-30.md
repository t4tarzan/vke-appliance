# SOP knowledge — sop_registry · sop_gaps · sop_effectiveness

Q: What does the SOP say for 'node pressure eviction'?
A: When pods are Evicted for ephemeral-storage, run the disk triage SOP: `crictl rmi --prune` on the node, rotate container logs, then re-apply the workload with an ephemeral-storage request. Effectiveness in sop_effectiveness: 0.91.

Q: Which runbook covers 'failed rollout rollback'?
A: For a rollout that leaves old replicas pending termination, the SOP is `kubectl rollout undo`, verify the previous ReplicaSet serves, THEN diagnose the new image offline. Never debug a broken rollout in place on prod.

Q: sop_gaps logged a query about 'certificate rotation'?
A: kubelet client cert expiry shows as `x509: certificate has expired` in agent_communications. SOP: renew via the cluster CA, restart kubelet, confirm Ready — and register the expiry date in the alert calendar. (This query previously appeared in sop_gaps — the SOP now covers it; the gap cluster is closed.)

Q: An operator asked about 'pvc stuck terminating'?
A: A PVC stuck Terminating almost always has a pod still mounting it. SOP: find the consumer with `kubectl describe pvc`, delete/reschedule it, and only clear finalizers as a last resort with storage-team sign-off.

Q: What does the SOP say for 'dns resolution failures'?
A: Intermittent `i/o timeout` on cluster DNS: check CoreDNS pod restarts and conntrack table saturation on the nodes; the SOP raises the CoreDNS replica count and node conntrack max before touching application pods.

Q: Which runbook covers 'noisy neighbour cpu'?
A: Throttling without saturation on a shared node = noisy neighbour. SOP: confirm with per-pod cpu_limit vs throttled seconds, then set a guaranteed QoS class for the victim or taint the node class for the offender.

Q: sop_gaps logged a query about 'node pressure eviction'?
A: When pods are Evicted for ephemeral-storage, run the disk triage SOP: `crictl rmi --prune` on the node, rotate container logs, then re-apply the workload with an ephemeral-storage request. Effectiveness in sop_effectiveness: 0.91. (This query previously appeared in sop_gaps — the SOP now covers it; the gap cluster is closed.)

Q: An operator asked about 'failed rollout rollback'?
A: For a rollout that leaves old replicas pending termination, the SOP is `kubectl rollout undo`, verify the previous ReplicaSet serves, THEN diagnose the new image offline. Never debug a broken rollout in place on prod.

Q: What does the SOP say for 'certificate rotation'?
A: kubelet client cert expiry shows as `x509: certificate has expired` in agent_communications. SOP: renew via the cluster CA, restart kubelet, confirm Ready — and register the expiry date in the alert calendar.

Q: Which runbook covers 'pvc stuck terminating'?
A: A PVC stuck Terminating almost always has a pod still mounting it. SOP: find the consumer with `kubectl describe pvc`, delete/reschedule it, and only clear finalizers as a last resort with storage-team sign-off.

Q: sop_gaps logged a query about 'dns resolution failures'?
A: Intermittent `i/o timeout` on cluster DNS: check CoreDNS pod restarts and conntrack table saturation on the nodes; the SOP raises the CoreDNS replica count and node conntrack max before touching application pods. (This query previously appeared in sop_gaps — the SOP now covers it; the gap cluster is closed.)

Q: An operator asked about 'noisy neighbour cpu'?
A: Throttling without saturation on a shared node = noisy neighbour. SOP: confirm with per-pod cpu_limit vs throttled seconds, then set a guaranteed QoS class for the victim or taint the node class for the offender.

Q: What does the SOP say for 'node pressure eviction'?
A: When pods are Evicted for ephemeral-storage, run the disk triage SOP: `crictl rmi --prune` on the node, rotate container logs, then re-apply the workload with an ephemeral-storage request. Effectiveness in sop_effectiveness: 0.91.

Q: Which runbook covers 'failed rollout rollback'?
A: For a rollout that leaves old replicas pending termination, the SOP is `kubectl rollout undo`, verify the previous ReplicaSet serves, THEN diagnose the new image offline. Never debug a broken rollout in place on prod.

Q: sop_gaps logged a query about 'certificate rotation'?
A: kubelet client cert expiry shows as `x509: certificate has expired` in agent_communications. SOP: renew via the cluster CA, restart kubelet, confirm Ready — and register the expiry date in the alert calendar. (This query previously appeared in sop_gaps — the SOP now covers it; the gap cluster is closed.)

Q: An operator asked about 'pvc stuck terminating'?
A: A PVC stuck Terminating almost always has a pod still mounting it. SOP: find the consumer with `kubectl describe pvc`, delete/reschedule it, and only clear finalizers as a last resort with storage-team sign-off.

Q: What does the SOP say for 'dns resolution failures'?
A: Intermittent `i/o timeout` on cluster DNS: check CoreDNS pod restarts and conntrack table saturation on the nodes; the SOP raises the CoreDNS replica count and node conntrack max before touching application pods.

Q: Which runbook covers 'noisy neighbour cpu'?
A: Throttling without saturation on a shared node = noisy neighbour. SOP: confirm with per-pod cpu_limit vs throttled seconds, then set a guaranteed QoS class for the victim or taint the node class for the offender.

Q: sop_gaps logged a query about 'node pressure eviction'?
A: When pods are Evicted for ephemeral-storage, run the disk triage SOP: `crictl rmi --prune` on the node, rotate container logs, then re-apply the workload with an ephemeral-storage request. Effectiveness in sop_effectiveness: 0.91. (This query previously appeared in sop_gaps — the SOP now covers it; the gap cluster is closed.)

Q: An operator asked about 'failed rollout rollback'?
A: For a rollout that leaves old replicas pending termination, the SOP is `kubectl rollout undo`, verify the previous ReplicaSet serves, THEN diagnose the new image offline. Never debug a broken rollout in place on prod.

Q: What does the SOP say for 'certificate rotation'?
A: kubelet client cert expiry shows as `x509: certificate has expired` in agent_communications. SOP: renew via the cluster CA, restart kubelet, confirm Ready — and register the expiry date in the alert calendar.

Q: Which runbook covers 'pvc stuck terminating'?
A: A PVC stuck Terminating almost always has a pod still mounting it. SOP: find the consumer with `kubectl describe pvc`, delete/reschedule it, and only clear finalizers as a last resort with storage-team sign-off.

Q: sop_gaps logged a query about 'dns resolution failures'?
A: Intermittent `i/o timeout` on cluster DNS: check CoreDNS pod restarts and conntrack table saturation on the nodes; the SOP raises the CoreDNS replica count and node conntrack max before touching application pods. (This query previously appeared in sop_gaps — the SOP now covers it; the gap cluster is closed.)

Q: An operator asked about 'noisy neighbour cpu'?
A: Throttling without saturation on a shared node = noisy neighbour. SOP: confirm with per-pod cpu_limit vs throttled seconds, then set a guaranteed QoS class for the victim or taint the node class for the offender.

Q: What does the SOP say for 'node pressure eviction'?
A: When pods are Evicted for ephemeral-storage, run the disk triage SOP: `crictl rmi --prune` on the node, rotate container logs, then re-apply the workload with an ephemeral-storage request. Effectiveness in sop_effectiveness: 0.91.

Q: Which runbook covers 'failed rollout rollback'?
A: For a rollout that leaves old replicas pending termination, the SOP is `kubectl rollout undo`, verify the previous ReplicaSet serves, THEN diagnose the new image offline. Never debug a broken rollout in place on prod.

Q: sop_gaps logged a query about 'certificate rotation'?
A: kubelet client cert expiry shows as `x509: certificate has expired` in agent_communications. SOP: renew via the cluster CA, restart kubelet, confirm Ready — and register the expiry date in the alert calendar. (This query previously appeared in sop_gaps — the SOP now covers it; the gap cluster is closed.)

Q: An operator asked about 'pvc stuck terminating'?
A: A PVC stuck Terminating almost always has a pod still mounting it. SOP: find the consumer with `kubectl describe pvc`, delete/reschedule it, and only clear finalizers as a last resort with storage-team sign-off.

Q: What does the SOP say for 'dns resolution failures'?
A: Intermittent `i/o timeout` on cluster DNS: check CoreDNS pod restarts and conntrack table saturation on the nodes; the SOP raises the CoreDNS replica count and node conntrack max before touching application pods.

Q: Which runbook covers 'noisy neighbour cpu'?
A: Throttling without saturation on a shared node = noisy neighbour. SOP: confirm with per-pod cpu_limit vs throttled seconds, then set a guaranteed QoS class for the victim or taint the node class for the offender.
