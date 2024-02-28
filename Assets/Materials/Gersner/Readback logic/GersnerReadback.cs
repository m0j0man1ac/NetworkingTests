using System.Collections;
using System.Collections.Generic;
using UnityEditor.Build;
using UnityEditor.PackageManager.Requests;
using UnityEngine;
using UnityEngine.Rendering;

[RequireComponent(typeof(Rigidbody), typeof(Collider))]
public class GersnerReadback : MonoBehaviour
{
    //vars
    [SerializeField]
    private ComputeShader computeShader = default;

    [SerializeField]
    private int GerstnerBackstepIterations = 2;

    [SerializeField]
    private Material oceanSource;
    private Vector4 WaveA;
    private Vector4 WaveB;
    private Vector4 WaveC;

    private Rigidbody rb;
    [SerializeField]
    private BoxCollider collider;
    [SerializeField]
    private Vector2 waveCheckPoints = new Vector2(3,3);

    private Vector3[] originPoints;

    //compute shader stuff
    int kernelID;
    private int bufferSize = 9;
    private ComputeBuffer originPositionsBuffer;
    private ComputeBuffer wavePositionsBuffer;

    private void OnEnable()
    {
        bufferSize = (int)waveCheckPoints.x * (int)waveCheckPoints.y;
        originPoints = new Vector3[bufferSize];
        dataRecieved = new Vector3[bufferSize];

        //create compute buffer
        originPositionsBuffer = new ComputeBuffer(bufferSize, sizeof(float) * 3);
        wavePositionsBuffer = new ComputeBuffer(bufferSize, sizeof(float) * 3);
        
        //cache kernel ID we will be dispatching
        kernelID = computeShader.FindKernel("Main");

        //bind
        computeShader.SetBuffer(kernelID, "InPositions", originPositionsBuffer);
        computeShader.SetBuffer(kernelID, "Positions", wavePositionsBuffer);
        //set data
        originPositionsBuffer.SetData(new Vector3[]{transform.position});
        wavePositionsBuffer.SetData(new Vector3[]{transform.position});

        //set unchanging data
        computeShader.SetInt("_BufferSize", bufferSize);
        computeShader.SetInt("_idX", (int)waveCheckPoints.x);
        computeShader.SetInt("_idY", (int)waveCheckPoints.y);

        //get wave data
        UpdateWaveVectors();
    }

    private void OnDisable()
    {
        wavePositionsBuffer?.Release();
        originPositionsBuffer?.Release();
    }

    [SerializeField]
    private Transform centerOfMass;

    private void Start()
    {
        //rb.centerOfMass = centerOfMass.localPosition;
        //run
        computeShader.Dispatch(kernelID, (int)waveCheckPoints.x, (int)waveCheckPoints.y, 1);
        // Asynchronous readback
        AsyncGPUReadback.Request(wavePositionsBuffer, OnDataRecieved);

        //get rb and collider
        rb = GetComponent<Rigidbody>();
        collider = GetComponent<BoxCollider>();
    }

    private void SetOriginPoints()
    {
        var temp = new Vector3[bufferSize];

        float minX = -collider.size.x/2f + collider.size.x/waveCheckPoints.x/2f;
        float minZ = -collider.size.z/2f + collider.size.z/waveCheckPoints.y/2f;

        for (int x = 0; x < waveCheckPoints.x; x++)
        {
            for (int z = 0; z < waveCheckPoints.y; z++)
            {
                float xPos = minX + x / (waveCheckPoints.x) * collider.size.x;
                float zPos = minZ + z / (waveCheckPoints.y) * collider.size.z;
                temp[x*(int)waveCheckPoints.x + z] = 
                    collider.transform.TransformPoint(new Vector3(xPos, collider.center.y - collider.size.y / 2, zPos));
            }
        }

        originPoints = temp;
    }

    private void UpdateWaveVectors()
    {
        //get values from the ocean material
        WaveA = oceanSource.GetVector("_WaveA");
        WaveB = oceanSource.GetVector("_WaveB");
        WaveC = oceanSource.GetVector("_WaveC");

        //send data to the vars on compute shader
        computeShader.SetVector("_WaveA", WaveA);
        computeShader.SetVector("_WaveB", WaveB);
        computeShader.SetVector("_WaveC", WaveC);
    }

    // Update is called once per frame
    void Update()
    {
        //set per frame data on shader
        //Debug.Log(Time.timeSinceLevelLoad);
        SetOriginPoints();
        originPositionsBuffer.SetData(originPoints);
        computeShader.SetFloat("_Time", Time.timeSinceLevelLoad);
    }

    private void OnDataRecieved(AsyncGPUReadbackRequest request)
    {
        if(request.hasError)
        {
            Debug.LogError("gpu readback problem");
            return;
        }
        //Debug.Log("isDone" + request.done);
        //Debug.Log("read data as single vector 3" + request.GetData<Vector3>().ToArray()[0]);
        //Debug.Log("read data as array" + request.GetData<Vector3>().ToArray());

        dataRecieved = request.GetData<Vector3>().ToArray();

        //Vector3[] data = request.GetData<Vector3>().ToArray();
        //transform.position = new Vector3(transform.position.x, data[0].y, transform.position.z);

        UpdateWaveVectors();
        computeShader.Dispatch(kernelID, (int)waveCheckPoints.x, (int)waveCheckPoints.y, 1);
        AsyncGPUReadback.Request(wavePositionsBuffer, OnDataRecieved);
    }

    private Vector3[] dataRecieved;

    private const float WATER_DENSITY = 997; 
            
    private void FixedUpdate()
    {
        if (dataRecieved.Length == 0) return;

        float colVolume = collider.size.x * collider.size.y * collider.size.z;
        //do the physics
        for(int i=0; i<bufferSize; i++)
        {
            //get displacement percentage
            var dif = dataRecieved[i] - originPoints[i];
            Debug.Log("dif " + dif);
            float percent = Mathf.Clamp(dif.y / collider.size.y, 0f, 1f);
            Debug.Log("percent " + percent);

            //if (percent <= 0f) break;

            Vector3 forceToAdd = Vector3.up * WATER_DENSITY * (colVolume / bufferSize) * percent * Mathf.Abs(Physics.gravity.y);
            Debug.Log("force to add " + forceToAdd);
            rb.AddForceAtPosition(forceToAdd / 2, 
                originPoints[i], ForceMode.Force);
        }
    }

    private void OnDrawGizmosSelected()
    {
        float minX = - collider.size.x / 2;
        float minZ = - collider.size.z / 2;

        Gizmos.color = Color.green;

        SetOriginPoints();
        for (int i = 0; i < bufferSize; i++)
        {
            var p = originPoints[i];
            Gizmos.DrawCube(p, Vector3.one * .2f);

            if (dataRecieved.Length > 0)
                Gizmos.DrawLine(p, dataRecieved[i]);
        }
    }
}
