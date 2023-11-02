using UnityEngine;

public class WaterWaveController : MonoBehaviour
{
    [Header("Liquid")]
    [SerializeField] private Renderer rend;
    [SerializeField] private float MaxWobble = 0.03f; // Amplitud maxima
    [SerializeField] private float WobbleSpeed = 1f;

    private Vector3 lastPos;
    private Vector3 lastRot;
    private Vector3 velocity;
    private Vector3 angularVelocity;

    private float wobbleAmountX;
    private float wobbleAmountZ;
    private float wobbleAmountToAddX;
    private float wobbleAmountToAddZ;
    private float pulse; // Se utiliza para calcular una onda senoidal para el efecto
    private float time;

    private void Update()
    {
        time += Time.deltaTime;

        // Disminuyo la onda con el tiempo
        wobbleAmountToAddX = Mathf.Lerp(wobbleAmountToAddX, 0, Time.deltaTime);
        wobbleAmountToAddZ = Mathf.Lerp(wobbleAmountToAddZ, 0, Time.deltaTime);

        // Calculo la onda sinoidal
        pulse = 2 * Mathf.PI * WobbleSpeed; // Calculo para obtener la frecuencia de la onda sinoidal
        wobbleAmountX = wobbleAmountToAddX * Mathf.Sin(pulse * time);
        wobbleAmountZ = wobbleAmountToAddZ * Mathf.Sin(pulse * time);

        // Actualizo el shader
        rend.material.SetFloat("_WaveAmplitudeX", wobbleAmountX);
        rend.material.SetFloat("_WaveAmplitudeZ", wobbleAmountZ);

        // Calculo la velocidad y la velocidad angular
        velocity = (lastPos - transform.position) / Time.deltaTime;
        angularVelocity = transform.rotation.eulerAngles - lastRot;

        // Clampeo una velocidad fija para la onda
        // 1) Multiplico la velocidad angular * 0.2f para reducir su impacto
        // 2) Sumo la velocidad para combinar ambas velocidades
        // 3) Multiplico con MaxWobble para escalar el valor anterior con la amplitud maxima
        // 4) Clampeo
        // 5) Se lo sumo a wobbleAmount para generar el efecto de la onda
        wobbleAmountToAddX += Mathf.Clamp((velocity.x + (angularVelocity.z * 0.2f)) * MaxWobble, -MaxWobble, MaxWobble);
        wobbleAmountToAddZ += Mathf.Clamp((velocity.z + (angularVelocity.x * 0.2f)) * MaxWobble, -MaxWobble, MaxWobble);

        // Guardo la ultima position y rotacion
        lastPos = transform.position;
        lastRot = transform.rotation.eulerAngles;
    }
}