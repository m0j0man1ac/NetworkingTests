using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class BoatMove : MonoBehaviour
{

    private Rigidbody rb;

    [SerializeField]
    private float moveSpeed;
    [SerializeField]
    private float steerSpeed;
    [SerializeField]
    private float wheelTurnSpeed = 1;

    [SerializeField]
    private Transform boatWheel;

    // Start is called before the first frame update
    void Start()
    {
        rb = GetComponent<Rigidbody>();
        
    }

    //private float currentSteering;
    float steerDir = 0;

    private void Update()
    {
        steerDir -= steerDir * .5f * Time.deltaTime;

        if (Input.GetKey(KeyCode.D)) steerDir += Time.deltaTime * wheelTurnSpeed;
        if (Input.GetKey(KeyCode.A)) steerDir -= Time.deltaTime * wheelTurnSpeed;
        Mathf.Clamp(steerDir, -1f, 1f);

        boatWheel.localEulerAngles = -Vector3.fwd * steerDir * 180f;
    }

    // Update is called once per frame
    void FixedUpdate()
    {
        if(Input.GetKey(KeyCode.W))
        {
            Debug.Log("forward");
            rb.AddForce(transform.forward * moveSpeed, ForceMode.Acceleration);
        }

        float steerForwardMult = Mathf.Clamp01(transform.InverseTransformVector(rb.velocity).z / 10);
        rb.AddRelativeTorque(transform.up * steerSpeed * steerDir * steerForwardMult, ForceMode.Acceleration);
    }
}
