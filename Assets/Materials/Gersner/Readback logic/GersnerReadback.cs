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
    private Material oceanSource;
    private Vector4 WaveA;
    private Vector4 WaveB;
    private Vector4 WaveC;

    private Rigidbody rb;
    [SerializeField]
    private BoxCollider collider;
    [SerializeField]
    private Vector2 waveCheckPoints = new Vector2(3,3);

    //compute shader stuff
    int kernelID;
    private const int bufferSize = 1;
    private ComputeBuffer originPositionsBuffer;
    private ComputeBuffer wavePositionsBuffer;

    private void OnEnable()
    {
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

        //get wave data
        UpdateWaveVectors();
    }

    private void OnDisable()
    {
        wavePositionsBuffer?.Release();
        originPositionsBuffer?.Release();
    }

    private void Start()
    {
        //run
        computeShader.Dispatch(kernelID, 1, 1, 1);
        // Asynchronous readback
        AsyncGPUReadback.Request(wavePositionsBuffer, OnDataRecieved);

        //get rb and collider
        rb = GetComponent<Rigidbody>();
        collider = GetComponent<BoxCollider>();
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
        originPositionsBuffer.SetData(new Vector3[]{transform.position});
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
        Debug.Log("read data as single vector 3" + request.GetData<Vector3>().ToArray()[0]);
        //Debug.Log("read data as array" + request.GetData<Vector3>().ToArray());

        Vector3[] data = request.GetData<Vector3>().ToArray();
        transform.position = new Vector3(transform.position.x, data[0].y, transform.position.z);

        UpdateWaveVectors();
        computeShader.Dispatch(kernelID, 1, 1, 1);
        AsyncGPUReadback.Request(wavePositionsBuffer, OnDataRecieved);
    }

    private void OnDrawGizmosSelected()
    {
        float minX = - collider.size.x / 2;
        float minZ = - collider.size.z / 2;

        Gizmos.color = Color.green;

        for(int x = 0; x<waveCheckPoints.x; x++)
        {
            for(int z =0; z<waveCheckPoints.y; z++)
            {
                float xPos = minX + x /(waveCheckPoints.x - 1) * collider.size.x;
                float zPos = minZ + z /(waveCheckPoints.y - 1) * collider.size.z;
                Gizmos.DrawCube(collider.transform.TransformPoint(new Vector3(xPos, collider.center.y - collider.size.y/2, zPos)), 
                    Vector3.one * .2f);
            }
        }


    }
}
