using Codice.Client.GameUI.Update;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using TMPro;
using UnityEngine.UIElements;

public class VertexBouncer : MonoBehaviour
{

    Vector3 BouncePosition;
    Vector3 BounceDir;

    float bounceStartTime;

    [SerializeField]
    private TMP_Text
        timeText,
        vectorText;

    private Renderer renderer;

    private float impactLifetime;

    const string TIME_FIELD = "Time: {0}\r\nImpact Time: {1}\r\nImpact LifeTime: {2}";
    const string VECTOR_FIELD = "Impact Pos: {0}\r\nImpact Dir: {1}";

    // Update is called once per frame
    void Update()
    {
        if (Input.GetMouseButtonDown(0))
        {
            Debug.Log("clicked");

            var ray = Camera.main.ScreenPointToRay(Input.mousePosition);

            var cameraPos = Camera.main.transform.position;
            var point = Camera.main.ScreenToWorldPoint(Input.mousePosition);
            
            RaycastHit hit;
            if(Physics.Raycast(ray, out hit, 100))
            {
                Debug.Log("hit " + hit.transform.name);

                BounceDir = -hit.transform.InverseTransformDirection(hit.normal);
                //BounceDir = ray.direction;
                BouncePosition = hit.transform.InverseTransformPoint(hit.point);

                bounceStartTime = Time.time;

                renderer = hit.transform.GetComponent<Renderer>();
                renderer.material.SetVector("_ImpactPoint", BouncePosition);
                renderer.material.SetVector("_ImpactDir", BounceDir);
                renderer.material.SetFloat("_ImpactTime", bounceStartTime);
            }
        }

        UpdateUI();
    }

    void UpdateUI()
    {
        if (Mathf.Abs(bounceStartTime - Time.time) <= 2f)
            impactLifetime = Mathf.Abs(bounceStartTime - Time.time);
        else
            impactLifetime = 0f;

        timeText.text = string.Format(TIME_FIELD, Time.time, bounceStartTime, impactLifetime);

        vectorText.text = string.Format(VECTOR_FIELD, BouncePosition, BounceDir);
    }

    private void OnDrawGizmos()
    {
        if(impactLifetime > 0f)
        {
            Gizmos.color = Color.yellow;
            Gizmos.DrawWireSphere(BouncePosition, .2f);
            Gizmos.color = Color.blue;
            Gizmos.DrawLine(BouncePosition, BouncePosition - BounceDir.normalized*3);
        }
    }
}
